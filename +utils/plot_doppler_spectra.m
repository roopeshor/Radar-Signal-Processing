
function plot_doppler_spectra(cfg)
%plot_doppler_spectra  plots doppler spectra and overlayes computed & reference moments
arguments
	cfg.spectra (:, 1024) double

	% computed moment
	cfg.comp_m (1, :) double = []
	% reference moment
	cfg.ref_m (1, :) double = []
	% direction of beam
	cfg.direction string
	% height array
	cfg.heights (1, :) double
	% max doppler velocity or doppler frequency
	cfg.x_max double = 30
	% whether to add legends
	cfg.add_legend logical = true

	cfg.comp_m_color = "black"
	cfg.ref_m_color = "red"
	% what is being plotted? frequency shift ("freq") or velocity ("velocity")
	% if velocity is used, the spectrum and given moments will be flipped left-right
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
