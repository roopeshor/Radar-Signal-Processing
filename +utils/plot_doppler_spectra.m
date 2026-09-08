
function plot_doppler_spectra(cfg)
%plot_doppler_spectra  plots doppler spectra and overlayes computed & reference moments
arguments
	cfg.spectra (:, 1024) double

	% computed moment
	cfg.comp_m (1, :) double
	% reference moment
	cfg.ref_m (1, :) double
	% direction of beam
	cfg.direction string
	% height array
	cfg.heights (1, :) double
	% max doppler velocity or doppler frequency
	cfg.x_max = 30
	% whether to add legends
	cfg.add_legend = true

	cfg.comp_m_color = "black"
	cfg.ref_m_color = "red"
	% what is being plotted? frequency shift ("freq") or velocity ("velocity")
	% if velocity is used, the spectrum and given moments will be flipped left-right
	cfg.x_axis_type = "velocity"
end

x_bounds = [-cfg.x_max, cfg.x_max];
y_bounds = [min(cfg.heights), max(cfg.heights)];
imagesc(x_bounds, y_bounds, cfg.spectra);

hold on;
plot(cfg.comp_m, cfg.heights, '-', 'LineWidth', 1, 'Color', cfg.comp_m_color);
plot(cfg.ref_m, cfg.heights, '-', 'LineWidth', 1, 'Color', cfg.ref_m_color);
xlim(x_bounds);
hold off;

set(gca, 'YDir', 'normal');
colormap('Parula');

xlabel('Doppler Velocity (m/s)');
ylabel('Altitude (km)');
title(cfg.direction);

if cfg.add_legend; legend(["comp", "ref"]);  end
end
