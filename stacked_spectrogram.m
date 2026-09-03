function stacked_spectrogram(data, y_ticks, x_ticks, cfg)
	%stacked_spectrogram  creates a stacked spectrogram.
	%    It can render plots with single color or gradient according to function value
	%    Optionally it can also mark max peak in each graph, and a reference line at given point

arguments
	data (:, :) double
	y_ticks (1, :) double = linspace(0,1,length(data(:, 1)))
	x_ticks (1, :) double = linspace(0,1,length(data))

	% scaling of amplitude of the spectral peaks.
	cfg.amplitude_scale double = 1.2

	% color of stacked plots
	cfg.plot_color = "blue"

	% whether to plot the lines with some gradient. if so the particular gradient should be specified in plot_color
	cfg.plot_gradiated = false

	% whether to add colorbar when plotting with amplitude gradient
	cfg.plot_add_colorbar = false

	% thickness of stacked plot
	cfg.plot_thick double = 1

	% color of baseline
	cfg.baseline_color = [0.5, 0.5, 0.5]

	% set this to 0 to remove line below every stacked plot
	cfg.baseline_thick double = 0

	% peak marker, setting this to empty string will not draw any marker
	cfg.peak_marker = "blue*"

	% size of peak marker, setting this to 0 will not draw any marker
	cfg.marker_size = 4

	% Where will be the reference line. By default its x=0
	cfg.ref_line_pos double = 0

	% thickness of x=0 reference line. set this to 0 to remove reference line
	cfg.ref_line_thick double = 1

	% color of reference line
	cfg.ref_line_color = "red"

	% fraction of input data to skip, 1 => nothing is skipped, increasing this decreases number of points plotted improving performance
	cfg.decimate_factor int32 = 1
end


if cfg.decimate_factor > 1
	% Decimate the horizontal data before constructing the blocks
	x_ticks = x_ticks(1:cfg.decimate_factor:end);
	data = data(:, 1:cfg.decimate_factor:end);
end

%%% Amplitude scaling.
% This finds the correct scale so that a waveform entirely fits in its given y range. amplitude_scaling does further scaling
plot_dy = y_ticks(2) - y_ticks(1); % assume uniform tick size
data(isinf(data)) = NaN;
[y_max, y_max_idx] = max(data, [], 2, 'omitnan');
y_min  = min(data, [], 2, 'omitnan');
y_diff_max = max(y_max - y_min);
cfg.amplitude_scale = cfg.amplitude_scale * plot_dy / y_diff_max;

y_count = length(y_ticks);
y_stacked_all = y_ticks' + (data * cfg.amplitude_scale);

fig = figure();
ax = axes(Parent=fig, SortMethod='childorder');
hold(ax, 'on');

if cfg.baseline_thick > 0
	X_base = repmat([x_ticks(1); x_ticks(end); NaN], y_count, 1);
	Y_base = reshape([y_ticks; y_ticks; NaN(1, y_count)], [], 1);
	plot(ax, X_base, Y_base, Color=cfg.baseline_color, LineWidth=cfg.baseline_thick);
end

% Vertical Reference Line at x = 0
if cfg.ref_line_thick > 0
	xline(cfg.ref_line_pos, Color=cfg.ref_line_color, LineWidth=cfg.ref_line_thick);
end

nans = NaN(y_count, 1);
% Create blocks with an extra NaN column at the end of each line
% This forces MATLAB to drop the pen before starting the next line
% also Flatten the blocks row-by-row into a single long row vector
X_ticks   = reshape([repmat(x_ticks, y_count, 1), nans]', 1, []);
Y_stacked = reshape([y_stacked_all, nans]', 1, []);

if cfg.plot_gradiated
	Y_vals  = reshape([data, nans]', 1, []);

	X_final = [X_ticks; X_ticks];
	Y_final = [Y_stacked; Y_stacked];
	C_final = [Y_vals; Y_vals];
	Z_final = zeros(size(X_final));

	s = surface(ax, X_final, Y_final, Z_final, C_final, ...
		FaceColor='none', ...
		EdgeColor='interp', ...
		LineWidth=cfg.plot_thick);
	s.AlignVertexCenters = 'off';

	colormap(ax, cfg.plot_color);
	if cfg.plot_add_colorbar
		colorbar(ax);
	end
	view(2);
else
	plot(ax, X_ticks, Y_stacked, Color=cfg.plot_color, LineWidth=cfg.plot_thick);
end

% Find and mark the peak (blue triangle)
if cfg.peak_marker ~= "" && cfg.marker_size > 0
	y_max_x            = x_ticks(y_max_idx)';
	y_max_offset       = y_ticks + (y_max' * cfg.amplitude_scale);
	plot( ...
		y_max_x, y_max_offset, cfg.peak_marker, ...
		MarkerSize      = cfg.marker_size ...
		);
end

end
