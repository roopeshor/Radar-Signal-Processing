function plot_doppler_spectra(cfg)
% UTILS.PLOT_DOPPLER_SPECTRA Renders range-Doppler spectrographs with overlaid computed and reference moments.

arguments (Input)
	% Power spectra matrix (RangeBins x NFFT).
	cfg.spectra (:, 1024) double
	% Computed Doppler moments profile vector.
	cfg.comp_m (1, :) double = []
	% Reference Doppler moments profile vector.
	cfg.ref_m (1, :) double = []
	% Beam direction label string.
	cfg.direction string = ""
	% Altitude heights profile vector.
	cfg.heights (1, :) double = []
	% Maximum unambiguous Doppler velocity or frequency bound.
	cfg.x_max double = 30
	% Flag to display plot legend.
	cfg.add_legend logical = true
	% Line color for computed moments curve.
	cfg.comp_m_color = "black"
	% Line color for reference moments curve.
	cfg.ref_m_color = "red"
	% X-axis domain mode ("velocity" or "freq").
	cfg.x_axis_type string = "velocity"
end

x_bounds = [-cfg.x_max, cfg.x_max];
y_bounds = [min(cfg.heights), max(cfg.heights)];
legnds = [];
if cfg.x_axis_type == "velocity"
	cfg.spectra = fliplr(cfg.spectra);
	cfg.comp_m = -cfg.comp_m;
	cfg.ref_m = -cfg.ref_m;
end

imagesc(x_bounds, y_bounds, cfg.spectra);
hold on;
if ~isempty(cfg.comp_m)
	plot(cfg.comp_m, cfg.heights, '-', 'LineWidth', 1, 'Color', cfg.comp_m_color);
	legnds = [legnds, "comp"];
end
if ~isempty(cfg.ref_m)
	plot(cfg.ref_m, cfg.heights, '-', 'LineWidth', 1, 'Color', cfg.ref_m_color);
	legnds = [legnds, "ref"];
end
xlim(x_bounds);
hold off;

set(gca, 'YDir', 'normal');
colormap('Parula');

xlabel("Doppler " + cfg.x_axis_type + " (m/s)");
ylabel('Altitude (km)');
title(cfg.direction);

if cfg.add_legend && ~isempty(legnds)
	legend(legnds);
end
end
