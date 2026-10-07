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
    [0.2422, 0.1504, 0.6603], [0.2444, 0.1534, 0.6728],
    [0.2464, 0.1569, 0.6847], [0.2484, 0.1607, 0.6961],
    [0.2503, 0.1648, 0.7071], [0.2522, 0.1689, 0.7179],
    [0.2540, 0.1732, 0.7286], [0.2558, 0.1773, 0.7393],
    [0.2576, 0.1814, 0.7501], [0.2594, 0.1854, 0.7610],
    [0.2611, 0.1893, 0.7719], [0.2628, 0.1932, 0.7828],
    [0.2645, 0.1972, 0.7937], [0.2661, 0.2011, 0.8043],
    [0.2676, 0.2052, 0.8148], [0.2691, 0.2094, 0.8249],
    [0.2704, 0.2138, 0.8346], [0.2717, 0.2184, 0.8439],
    [0.2729, 0.2231, 0.8528], [0.2740, 0.2280, 0.8612],
    [0.2749, 0.2330, 0.8692], [0.2758, 0.2382, 0.8767],
    [0.2766, 0.2435, 0.8840], [0.2774, 0.2489, 0.8908],
    [0.2781, 0.2543, 0.8973], [0.2788, 0.2598, 0.9035],
    [0.2794, 0.2653, 0.9094], [0.2798, 0.2708, 0.9150],
    [0.2802, 0.2764, 0.9204], [0.2806, 0.2819, 0.9255],
    [0.2809, 0.2875, 0.9305], [0.2811, 0.2930, 0.9352],
    [0.2813, 0.2985, 0.9397], [0.2814, 0.3040, 0.9441],
    [0.2814, 0.3095, 0.9483], [0.2813, 0.3150, 0.9524],
    [0.2811, 0.3204, 0.9563], [0.2809, 0.3259, 0.9600],
    [0.2807, 0.3313, 0.9636], [0.2803, 0.3367, 0.9670],
    [0.2798, 0.3421, 0.9702], [0.2791, 0.3475, 0.9733],
    [0.2784, 0.3529, 0.9763], [0.2776, 0.3583, 0.9791],
    [0.2766, 0.3638, 0.9817], [0.2754, 0.3693, 0.9840],
    [0.2741, 0.3748, 0.9862], [0.2726, 0.3804, 0.9881],
    [0.2710, 0.3860, 0.9898], [0.2691, 0.3916, 0.9912],
    [0.2670, 0.3973, 0.9924], [0.2647, 0.4030, 0.9935],
    [0.2621, 0.4088, 0.9946], [0.2591, 0.4145, 0.9955],
    [0.2556, 0.4203, 0.9965], [0.2517, 0.4261, 0.9974],
    [0.2473, 0.4319, 0.9983], [0.2424, 0.4378, 0.9991],
    [0.2369, 0.4437, 0.9996], [0.2311, 0.4497, 0.9995],
    [0.2250, 0.4559, 0.9985], [0.2189, 0.4620, 0.9968],
    [0.2128, 0.4682, 0.9948], [0.2066, 0.4743, 0.9926],
    [0.2006, 0.4803, 0.9906], [0.1950, 0.4861, 0.9887],
    [0.1903, 0.4919, 0.9867], [0.1869, 0.4975, 0.9844],
    [0.1847, 0.5030, 0.9819], [0.1831, 0.5084, 0.9793],
    [0.1818, 0.5138, 0.9766], [0.1806, 0.5191, 0.9738],
    [0.1795, 0.5244, 0.9709], [0.1785, 0.5296, 0.9677],
    [0.1778, 0.5349, 0.9641], [0.1773, 0.5401, 0.9602],
    [0.1768, 0.5452, 0.9560], [0.1764, 0.5504, 0.9516],
    [0.1755, 0.5554, 0.9473], [0.1740, 0.5605, 0.9432],
    [0.1716, 0.5655, 0.9393], [0.1686, 0.5705, 0.9357],
    [0.1649, 0.5755, 0.9323], [0.1610, 0.5805, 0.9289],
    [0.1573, 0.5854, 0.9254], [0.1540, 0.5902, 0.9218],
    [0.1513, 0.5950, 0.9182], [0.1492, 0.5997, 0.9147],
    [0.1475, 0.6043, 0.9113], [0.1461, 0.6089, 0.9080],
    [0.1446, 0.6135, 0.9050], [0.1429, 0.6180, 0.9022],
    [0.1408, 0.6226, 0.8998], [0.1383, 0.6272, 0.8975],
    [0.1354, 0.6317, 0.8953], [0.1321, 0.6363, 0.8932],
    [0.1288, 0.6408, 0.8910], [0.1253, 0.6453, 0.8887],
    [0.1219, 0.6497, 0.8862], [0.1185, 0.6541, 0.8834],
    [0.1152, 0.6584, 0.8804], [0.1119, 0.6627, 0.8770],
    [0.1085, 0.6669, 0.8734], [0.1048, 0.6710, 0.8695],
    [0.1009, 0.6750, 0.8653], [0.0964, 0.6789, 0.8609],
    [0.0914, 0.6828, 0.8562], [0.0855, 0.6865, 0.8513],
    [0.0789, 0.6902, 0.8462], [0.0713, 0.6938, 0.8409],
    [0.0628, 0.6972, 0.8355], [0.0535, 0.7006, 0.8299],
    [0.0433, 0.7039, 0.8242], [0.0328, 0.7071, 0.8183],
    [0.0234, 0.7103, 0.8124], [0.0155, 0.7133, 0.8064],
    [0.0091, 0.7163, 0.8003], [0.0046, 0.7192, 0.7941],
    [0.0019, 0.7220, 0.7878], [0.0009, 0.7248, 0.7815],
    [0.0018, 0.7275, 0.7752], [0.0046, 0.7301, 0.7688],
    [0.0094, 0.7327, 0.7623], [0.0162, 0.7352, 0.7558],
    [0.0253, 0.7376, 0.7492], [0.0369, 0.7400, 0.7426],
    [0.0504, 0.7423, 0.7359], [0.0638, 0.7446, 0.7292],
    [0.0770, 0.7468, 0.7224], [0.0899, 0.7489, 0.7156],
    [0.1023, 0.7510, 0.7088], [0.1141, 0.7531, 0.7019],
    [0.1252, 0.7552, 0.6950], [0.1354, 0.7572, 0.6881],
    [0.1448, 0.7593, 0.6812], [0.1532, 0.7614, 0.6741],
    [0.1609, 0.7635, 0.6671], [0.1678, 0.7656, 0.6599],
    [0.1741, 0.7678, 0.6527], [0.1799, 0.7699, 0.6454],
    [0.1853, 0.7721, 0.6379], [0.1905, 0.7743, 0.6303],
    [0.1954, 0.7765, 0.6225], [0.2003, 0.7787, 0.6146],
    [0.2061, 0.7808, 0.6065], [0.2118, 0.7828, 0.5983],
    [0.2178, 0.7849, 0.5899], [0.2244, 0.7869, 0.5813],
    [0.2318, 0.7887, 0.5725], [0.2401, 0.7905, 0.5636],
    [0.2491, 0.7922, 0.5546], [0.2589, 0.7937, 0.5454],
    [0.2695, 0.7951, 0.5360], [0.2809, 0.7964, 0.5266],
    [0.2929, 0.7975, 0.5170], [0.3052, 0.7985, 0.5074],
    [0.3176, 0.7994, 0.4975], [0.3301, 0.8002, 0.4876],
    [0.3424, 0.8009, 0.4774], [0.3548, 0.8016, 0.4669],
    [0.3671, 0.8021, 0.4563], [0.3795, 0.8026, 0.4454],
    [0.3921, 0.8029, 0.4344], [0.4050, 0.8031, 0.4233],
    [0.4184, 0.8030, 0.4122], [0.4322, 0.8028, 0.4013],
    [0.4463, 0.8024, 0.3904], [0.4608, 0.8018, 0.3797],
    [0.4753, 0.8011, 0.3691], [0.4899, 0.8002, 0.3586],
    [0.5044, 0.7993, 0.3480], [0.5187, 0.7982, 0.3374],
    [0.5329, 0.7970, 0.3267], [0.5470, 0.7957, 0.3159],
    [0.5609, 0.7943, 0.3050], [0.5748, 0.7929, 0.2941],
    [0.5886, 0.7913, 0.2833], [0.6024, 0.7896, 0.2726],
    [0.6161, 0.7878, 0.2622], [0.6297, 0.7859, 0.2521],
    [0.6433, 0.7839, 0.2423], [0.6567, 0.7818, 0.2329],
    [0.6701, 0.7796, 0.2239], [0.6833, 0.7773, 0.2155],
    [0.6963, 0.7750, 0.2075], [0.7091, 0.7727, 0.1998],
    [0.7218, 0.7703, 0.1924], [0.7344, 0.7679, 0.1852],
    [0.7468, 0.7654, 0.1782], [0.7590, 0.7629, 0.1717],
    [0.7710, 0.7604, 0.1658], [0.7829, 0.7579, 0.1608],
    [0.7945, 0.7554, 0.1570], [0.8060, 0.7529, 0.1546],
    [0.8172, 0.7505, 0.1535], [0.8281, 0.7481, 0.1536],
    [0.8389, 0.7457, 0.1546], [0.8495, 0.7435, 0.1564],
    [0.8600, 0.7413, 0.1587], [0.8703, 0.7392, 0.1615],
    [0.8804, 0.7372, 0.1650], [0.8903, 0.7353, 0.1695],
    [0.9000, 0.7336, 0.1749], [0.9093, 0.7321, 0.1815],
    [0.9184, 0.7308, 0.1890], [0.9272, 0.7298, 0.1973],
    [0.9357, 0.7290, 0.2061], [0.9440, 0.7285, 0.2151],
    [0.9523, 0.7284, 0.2237], [0.9606, 0.7285, 0.2312],
    [0.9689, 0.7292, 0.2373], [0.9770, 0.7304, 0.2418],
    [0.9842, 0.7330, 0.2446], [0.9900, 0.7365, 0.2429],
    [0.9946, 0.7407, 0.2394], [0.9966, 0.7458, 0.2351],
    [0.9971, 0.7513, 0.2309], [0.9972, 0.7569, 0.2267],
    [0.9971, 0.7626, 0.2224], [0.9969, 0.7683, 0.2181],
    [0.9966, 0.7740, 0.2138], [0.9962, 0.7798, 0.2095],
    [0.9957, 0.7856, 0.2053], [0.9949, 0.7915, 0.2012],
    [0.9938, 0.7974, 0.1974], [0.9923, 0.8034, 0.1939],
    [0.9906, 0.8095, 0.1906], [0.9885, 0.8156, 0.1875],
    [0.9861, 0.8218, 0.1846], [0.9835, 0.8280, 0.1817],
    [0.9807, 0.8342, 0.1787], [0.9778, 0.8404, 0.1757],
    [0.9748, 0.8467, 0.1726], [0.9720, 0.8529, 0.1695],
    [0.9694, 0.8591, 0.1665], [0.9671, 0.8654, 0.1636],
    [0.9651, 0.8716, 0.1608], [0.9634, 0.8778, 0.1582],
    [0.9619, 0.8840, 0.1557], [0.9608, 0.8902, 0.1532],
    [0.9601, 0.8963, 0.1507], [0.9596, 0.9023, 0.1480],
    [0.9595, 0.9084, 0.1450], [0.9597, 0.9143, 0.1418],
    [0.9601, 0.9203, 0.1382], [0.9608, 0.9262, 0.1344],
    [0.9618, 0.9320, 0.1304], [0.9629, 0.9379, 0.1261],
    [0.9642, 0.9437, 0.1216], [0.9657, 0.9494, 0.1168],
    [0.9674, 0.9552, 0.1116], [0.9692, 0.9609, 0.1061],
    [0.9711, 0.9667, 0.1001], [0.9730, 0.9724, 0.0938],
    [0.9749, 0.9782, 0.0872], [0.9769, 0.9839, 0.0805],
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
    export_path        = to_str(get_val('export_path',           'plots/plt.stacked_spectrogram.png'))
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
