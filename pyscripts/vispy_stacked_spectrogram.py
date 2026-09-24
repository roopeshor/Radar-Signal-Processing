#!/usr/bin/env python3
"""
vispy_stacked_spectrogram.py
High-performance stacked spectrogram renderer.
Uses matplotlib Agg (headless) for publication-quality output with proper
axes, color scales, anti-aliased gradients, and correct colormap support.
Runs as a persistent daemon to avoid repeated Python cold-start overhead.
"""
import sys
import os
import socket
import traceback

# ── Matplotlib headless setup (must happen before any other plt imports) ──────
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
from matplotlib.collections import LineCollection
from matplotlib.cm import ScalarMappable
import matplotlib.ticker as mticker

import numpy as np
import scipy.io
from PIL import Image

# ── MATLAB's parula colormap (256 RGB control points) ─────────────────────────
# Transcribed from MATLAB's built-in parula (R2014b+).  Registers as
# 'parula' in matplotlib's colormap registry on first import.
_PARULA_DATA = np.array([
    [0.2081, 0.1663, 0.5292], [0.2116, 0.1898, 0.5777],
    [0.2123, 0.2138, 0.6270], [0.2081, 0.2386, 0.6771],
    [0.1959, 0.2645, 0.7279], [0.1707, 0.2919, 0.7792],
    [0.1253, 0.3242, 0.8303], [0.0591, 0.3598, 0.8683],
    [0.0117, 0.3875, 0.8820], [0.0060, 0.4086, 0.8828],
    [0.0165, 0.4266, 0.8786], [0.0329, 0.4430, 0.8720],
    [0.0498, 0.4586, 0.8641], [0.0629, 0.4737, 0.8554],
    [0.0723, 0.4887, 0.8467], [0.0779, 0.5040, 0.8384],
    [0.0793, 0.5200, 0.8312], [0.0749, 0.5375, 0.8263],
    [0.0641, 0.5569, 0.8240], [0.0488, 0.5772, 0.8228],
    [0.0343, 0.5966, 0.8199], [0.0265, 0.6137, 0.8135],
    [0.0239, 0.6287, 0.8038], [0.0231, 0.6418, 0.7913],
    [0.0228, 0.6535, 0.7771], [0.0267, 0.6642, 0.7607],
    [0.0384, 0.6743, 0.7423], [0.0590, 0.6838, 0.7219],
    [0.0843, 0.6928, 0.6995], [0.1133, 0.7015, 0.6752],
    [0.1453, 0.7098, 0.6490], [0.1801, 0.7177, 0.6214],
    [0.2178, 0.7250, 0.5919], [0.2586, 0.7317, 0.5608],
    [0.3022, 0.7376, 0.5279], [0.3482, 0.7424, 0.4934],
    [0.3953, 0.7459, 0.4577], [0.4420, 0.7481, 0.4210],
    [0.4871, 0.7491, 0.3840], [0.5300, 0.7491, 0.3467],
    [0.5709, 0.7485, 0.3092], [0.6099, 0.7473, 0.2715],
    [0.6473, 0.7456, 0.2334], [0.6834, 0.7435, 0.1948],
    [0.7184, 0.7411, 0.1561], [0.7525, 0.7385, 0.1176],
    [0.7858, 0.7359, 0.0805], [0.8185, 0.7332, 0.0443],
    [0.8507, 0.7305, 0.0259], [0.8824, 0.7278, 0.0276],
    [0.9139, 0.7247, 0.0540], [0.9450, 0.7208, 0.0845],
    [0.9739, 0.7154, 0.1071], [0.9938, 0.7067, 0.1099],
    [0.9989, 0.6920, 0.0949], [0.9945, 0.6703, 0.0754],
    [0.9882, 0.6468, 0.0563], [0.9811, 0.6239, 0.0394],
    [0.9748, 0.6041, 0.0276], [0.9696, 0.5872, 0.0218],
    [0.9658, 0.5727, 0.0215], [0.9638, 0.5601, 0.0264],
    [0.9636, 0.5491, 0.0356], [0.9659, 0.5402, 0.0487],
])

_parula_cmap = mcolors.LinearSegmentedColormap.from_list(
    'parula', _PARULA_DATA, N=256)
matplotlib.colormaps.register(_parula_cmap, force=True)

# ── Helper type coercions ──────────────────────────────────────────────────────

def to_float(v, default=0.0):
    try:
        if isinstance(v, (int, float)):
            return float(v)
        return float(np.asarray(v).flat[0])
    except Exception:
        return float(default)

def to_int(v, default=0):
    try:
        if isinstance(v, (int, float)):
            return int(v)
        return int(np.asarray(v).flat[0])
    except Exception:
        return int(default)

def to_bool(v, default=False):
    try:
        if isinstance(v, (bool, np.bool_)):
            return bool(v)
        return bool(np.asarray(v).flat[0])
    except Exception:
        return bool(default)

def to_str(v, default=''):
    try:
        if isinstance(v, str):
            return v.strip()
        arr = np.asarray(v)
        if arr.dtype.kind in ('U', 'S'):
            return ''.join(arr.flat).strip()
        return str(arr.flat[0]).strip()
    except Exception:
        return str(default)

def parse_color(c, default=(0.0, 0.0, 0.0, 1.0)) -> tuple:
    """Parse any MATLAB color representation to an RGBA tuple."""
    if c is None:
        return default
    # Try string-based parsing first (handles numpy str_ / object arrays)
    s = to_str(c, '')
    if s:
        try:
            return mcolors.to_rgba(s)
        except (ValueError, TypeError):
            pass
    # Numeric array path
    if isinstance(c, (list, tuple, np.ndarray)):
        try:
            arr = np.asarray(c, dtype=float).squeeze()
            if arr.ndim == 1 and len(arr) == 3:
                return (float(arr[0]), float(arr[1]), float(arr[2]), 1.0)
            if arr.ndim == 1 and len(arr) == 4:
                return tuple(float(x) for x in arr)
        except (ValueError, TypeError):
            pass
    return default

def get_colormap(name):
    """Return a matplotlib Colormap, falling back gracefully."""
    name = to_str(name, 'parula').lower().strip()
    if name in matplotlib.colormaps:
        return matplotlib.colormaps[name]
    # Common MATLAB → matplotlib aliases
    aliases = {'hot': 'hot', 'cool': 'cool', 'jet': 'jet',
                'hsv': 'hsv', 'gray': 'gray', 'bone': 'bone',
                'copper': 'copper', 'pink': 'pink', 'spring': 'spring',
                'summer': 'summer', 'autumn': 'autumn', 'winter': 'winter',
                'colorcube': 'tab20', 'lines': 'tab10'}
    return matplotlib.colormaps.get(aliases.get(name, 'parula'), _parula_cmap)

def parse_marker(s):
    """Parse MATLAB-style marker string like 'blue*' into (color, marker)."""
    s = to_str(s, '')
    if not s:
        return None, None
    color_prefixes = [
        ('white', 'white'), ('black', 'black'), ('blue', 'blue'),
        ('red', 'red'), ('green', 'green'), ('yellow', 'yellow'),
        ('cyan', 'cyan'), ('magenta', 'magenta'),
        ('w', 'white'), ('k', 'black'), ('b', 'blue'),
        ('r', 'red'), ('g', 'green'), ('y', 'yellow'),
        ('c', 'cyan'), ('m', 'magenta'),
    ]
    color = 'white'
    for prefix, col in sorted(color_prefixes, key=lambda x: -len(x[0])):
        if s.startswith(prefix):
            color = col
            s = s[len(prefix):]
            break
    marker_map = {'.': '.', 'o': 'o', '*': '*', '^': '^', 'v': 'v',
                  '+': '+', 'x': 'x', 's': 's', 'd': 'D'}
    marker = marker_map.get(s, '.')
    return color, marker


# ── Core rendering ─────────────────────────────────────────────────────────────

def render_stacked_spectrogram(mat_path):
    data = scipy.io.loadmat(mat_path)

    spectrum = np.array(data['spectrum'], dtype=np.float64)
    y_ticks  = np.array(data['y_ticks'],  dtype=np.float64).flatten()
    x_ticks  = np.array(data['x_ticks'],  dtype=np.float64).flatten()

    cfg = data.get('cfg', None)

    def get_val(key, default) -> str:
        if cfg is not None and cfg.dtype.names and key in cfg.dtype.names:
            return cfg[key][0, 0]
        return default

    amplitude_scale    = to_float(get_val('amplitude_scale',    1.2))
    plot_color_raw     = get_val('plot_color',                   'blue')
    plot_gradiated     = to_bool(get_val('plot_gradiated',       False))
    plot_add_colorbar  = to_bool(get_val('plot_add_colorbar',    False))
    plot_thick         = to_float(get_val('plot_thick',          1.0))
    baseline_color_raw = get_val('baseline_color',               [0.5, 0.5, 0.5])
    baseline_thick     = to_float(get_val('baseline_thick',      0.0))
    peak_marker_raw    = get_val('peak_marker',                  'blue*')
    marker_size        = to_float(get_val('marker_size',         4.0))
    ref_line_pos       = to_float(get_val('ref_line_pos',        0.0))
    ref_line_thick     = to_float(get_val('ref_line_thick',      1.0))
    ref_line_color_raw = get_val('ref_line_color',               'red')
    decimate_factor    = to_int(get_val('decimate_factor',       1))
    x_axis_type        = to_str(get_val('x_axis_type',           'velocity'))
    export_dpi         = to_float(get_val('export_dpi',          700.0))
    export_path        = to_str(get_val('export_path',           'plots/stacked_spectrogram.png'))
    bg_color_raw       = get_val('bg_color',                     'white')

    # ── Preprocess data ────────────────────────────────────────────────────────
    if decimate_factor > 1:
        x_ticks  = x_ticks[::decimate_factor]
        spectrum = spectrum[:, ::decimate_factor]

    if x_axis_type == 'velocity':
        spectrum = np.fliplr(spectrum)

    spectrum[np.isinf(spectrum)] = np.nan

    plot_dy     = y_ticks[1] - y_ticks[0] if len(y_ticks) > 1 else 1.0
    y_max       = np.nanmax(spectrum, axis=1)
    y_min       = np.nanmin(spectrum, axis=1)
    y_diff_max  = np.nanmax(y_max - y_min)
    if y_diff_max > 0:
        amplitude_scale = amplitude_scale * plot_dy / y_diff_max

    y_count     = len(y_ticks)
    x_count     = len(x_ticks)
    y_stacked   = y_ticks[:, None] + spectrum * amplitude_scale  # (y, x)

    spec_min = np.nanmin(spectrum)
    spec_max = np.nanmax(spectrum)

    # ── Colors & styles ───────────────────────────────────────────────────────
    bg_color  = parse_color(bg_color_raw,     (1., 1., 1., 1.))
    bg_mpl    = bg_color[:3]                              # matplotlib facecolor
    text_color = 'white' if sum(bg_color[:3]) < 1.5 else 'black'  # contrast

    xlim = (float(np.min(x_ticks)), float(np.max(x_ticks)))
    ylim = (float(np.min(y_ticks)) - amplitude_scale,
            float(np.max(y_ticks)) + amplitude_scale)

    # ── Figure layout ─────────────────────────────────────────────────────────
    fig_w, fig_h = 10.0, 7.5
    fig, ax = plt.subplots(figsize=(fig_w, fig_h))
    ax.set_facecolor(bg_mpl)
    fig.patch.set_facecolor(bg_mpl)

    # ── 1. Baseline lines ─────────────────────────────────────────────────────
    if baseline_thick > 0:
        b_color = parse_color(baseline_color_raw, (0.5, 0.5, 0.5, 1.0))
        for yt in y_ticks:
            ax.axhline(yt, color=b_color[:3], linewidth=baseline_thick,
                       alpha=b_color[3], zorder=1)

    # ── 2. Reference vertical line ────────────────────────────────────────────
    if ref_line_thick > 0:
        r_color = parse_color(ref_line_color_raw, (1., 0., 0., 1.))
        ax.axvline(ref_line_pos, color=r_color[:3], linewidth=ref_line_thick,
                   alpha=r_color[3], zorder=2)

    # ── 3. Stacked spectral lines ─────────────────────────────────────────────
    if plot_gradiated:
        cmap     = get_colormap(to_str(plot_color_raw, 'parula'))
        norm_mpl = mcolors.Normalize(vmin=spec_min, vmax=spec_max)

        # Build all segments vectorially.
        # x_left/right: (1, x-1)  broadcast over y → (y, x-1)
        x_left  = x_ticks[:-1]                          # (x-1,)
        x_right = x_ticks[1:]                           # (x-1,)
        y_left  = y_stacked[:, :-1]                     # (y, x-1)
        y_right = y_stacked[:, 1:]                      # (y, x-1)

        # segs: (y*(x-1), 2, 2)  — each row: [[x0,y0],[x1,y1]]
        segs_flat = np.empty((y_count * (x_count - 1), 2, 2), dtype=np.float64)
        segs_flat[:, 0, 0] = np.broadcast_to(x_left,  (y_count, x_count - 1)).ravel()
        segs_flat[:, 1, 0] = np.broadcast_to(x_right, (y_count, x_count - 1)).ravel()
        segs_flat[:, 0, 1] = y_left.ravel()
        segs_flat[:, 1, 1] = y_right.ravel()

        # Color per segment: midpoint spectrum value
        seg_vals = 0.5 * (spectrum[:, :-1] + spectrum[:, 1:])   # (y, x-1)
        seg_vals = np.nan_to_num(seg_vals.ravel(), nan=spec_min)

        lc = LineCollection(segs_flat, cmap=cmap, norm=norm_mpl,
                            linewidths=plot_thick, zorder=3,
                            antialiased=True, capstyle='round')
        lc.set_array(seg_vals)
        ax.add_collection(lc)

        # ── Colorbar ──────────────────────────────────────────────────────────
        if plot_add_colorbar:
            sm = ScalarMappable(cmap=cmap, norm=norm_mpl)
            sm.set_array([])
            cbar = fig.colorbar(sm, ax=ax, fraction=0.03, pad=0.01)
            cbar.set_label('Spectrum (dB)', color=text_color, labelpad=6)
            plt.setp(plt.getp(cbar.ax.axes, 'yticklabels'), color=text_color)
            cbar.outline.set_edgecolor(text_color)
    else:
        line_color = parse_color(plot_color_raw, (0., 0., 1., 1.))
        # Build segments for single-color LineCollection
        x_left  = x_ticks[:-1]
        x_right = x_ticks[1:]
        y_left  = y_stacked[:, :-1]   # (y, x-1)
        y_right = y_stacked[:, 1:]    # (y, x-1)
        N = y_count * (x_count - 1)
        segs_flat = np.empty((N, 2, 2), dtype=np.float64)
        segs_flat[:, 0, 0] = np.broadcast_to(x_left,  (y_count, x_count - 1)).ravel()
        segs_flat[:, 1, 0] = np.broadcast_to(x_right, (y_count, x_count - 1)).ravel()
        segs_flat[:, 0, 1] = y_left.ravel()
        segs_flat[:, 1, 1] = y_right.ravel()
        lc = LineCollection(segs_flat, colors=[line_color[:3]],
                            linewidths=plot_thick, zorder=3,
                            antialiased=True, capstyle='round')
        ax.add_collection(lc)

    # ── 4. Peak markers ───────────────────────────────────────────────────────
    m_color, m_symbol = parse_marker(peak_marker_raw)
    if m_color and m_symbol and marker_size > 0:
        y_max_idx = np.nanargmax(spectrum, axis=1)
        x_peaks   = x_ticks[y_max_idx]
        y_peaks   = y_ticks + y_max * amplitude_scale
        ax.scatter(x_peaks, y_peaks, c=m_color, marker=m_symbol,
                   s=marker_size ** 2, zorder=5, linewidths=0)

    # ── 5. Axes styling ───────────────────────────────────────────────────────
    ax.set_xlim(*xlim)
    ax.set_ylim(*ylim)

    x_label = f'Doppler {x_axis_type} (m/s)'
    ax.set_xlabel(x_label, color=text_color, fontsize=10)
    ax.set_ylabel('Altitude (km)', color=text_color, fontsize=10)

    ax.tick_params(axis='both', colors=text_color, labelsize=8)
    for spine in ax.spines.values():
        spine.set_edgecolor(text_color)

    ax.xaxis.set_major_locator(mticker.AutoLocator())
    ax.yaxis.set_major_locator(mticker.AutoLocator())
    ax.xaxis.set_minor_locator(mticker.AutoMinorLocator())
    ax.yaxis.set_minor_locator(mticker.AutoMinorLocator())
    ax.tick_params(which='minor', length=2, colors=text_color)

    ax.grid(True, color=text_color, alpha=0.12, linewidth=0.4, zorder=0)

    plt.tight_layout(pad=0.8)

    # ── 6. Export ─────────────────────────────────────────────────────────────
    out_dir = os.path.dirname(os.path.abspath(export_path))
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    fig.savefig(export_path, dpi=export_dpi, bbox_inches='tight',
                facecolor=bg_mpl, edgecolor='none')
    plt.close(fig)


# ── Daemon server ──────────────────────────────────────────────────────────────

def run_server(port=28290):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('127.0.0.1', port))
    server.listen(5)
    print(f'VisPy Spectrogram Server listening on port {port}...', flush=True)

    while True:
        try:
            conn, _ = server.accept()
            raw = conn.recv(8192).decode('utf-8').strip()
            if not raw:
                conn.close()
                continue
            if raw == 'QUIT':
                conn.sendall(b'BYE\n')
                conn.close()
                break
            try:
                render_stacked_spectrogram(raw)
                conn.sendall(b'OK\n')
            except Exception as e:
                conn.sendall(f'ERROR: {e}\n'.encode('utf-8'))
            conn.close()
        except Exception:
            traceback.print_exc()


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--server':
        port = int(sys.argv[2]) if len(sys.argv) > 2 else 28290
        run_server(port)
    elif len(sys.argv) > 1:
        render_stacked_spectrogram(sys.argv[1])
