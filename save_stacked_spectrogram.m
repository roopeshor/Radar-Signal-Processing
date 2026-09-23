function save_stacked_spectrogram(spectrum, y_ticks, x_ticks, cfg)
	% save_stacked_spectrogram stacked spectrogram plotter and PNG exporter usinh VisPy backend .
	% Drop-in replacement for stacked_spectrogram.m

arguments
	spectrum (:, :) double
	y_ticks (1, :) double = linspace(0,1,size(spectrum, 1))
	x_ticks (1, :) double = linspace(0,1,size(spectrum, 2))

	% scaling of amplitude of the spectral peaks.
	cfg.amplitude_scale double = 1.2

	% color of stacked plots
	cfg.plot_color = "blue"

	% whether to plot the lines with some gradient
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

	% thickness of x=0 reference line
	cfg.ref_line_thick double = 1

	% color of reference line
	cfg.ref_line_color = "red"

	% fraction of input data to skip
	cfg.decimate_factor int32 = 1

	% X-axis domain mode ("velocity" or "freq")
	cfg.x_axis_type string = "velocity"

	% DPI for PNG output
	cfg.export_dpi double = 700

	% Export path for generated PNG file
	cfg.export_path string = "plots/stacked_spectrogram.png"

	% Background color of plot. Can be a color name (e.g. "white", "black") or [R G B] triplet
	cfg.bg_color = "#111"
end

% Convert any string fields in cfg to char arrays for scipy.io loadmat compatibility
fn = fieldnames(cfg);
for k = 1:numel(fn)
	val = cfg.(fn{k});
	if isstring(val)
		cfg.(fn{k}) = char(val);
	end
end

% Save data to temporary MAT file for fast serialization
temp_mat = [tempname, '_sp_py.mat'];
save(temp_mat, 'spectrum', 'y_ticks', 'x_ticks', 'cfg', '-v7');

% Clean up temp file on function exit
cleanup = onCleanup(@() delete_temp_file(temp_mat));

python_bin = "python";
if ~exist(python_bin, 'file')
	python_bin = "python3";
end
script_dir = fileparts(mfilename('fullpath'));
py_script = fullfile(script_dir, "pyscripts/vispy_stacked_spectrogram.py");
port = 28290;

connected = false;
try
	t = tcpclient('127.0.0.1', port, 'Timeout', 30.0);
	connected = true;
catch
	% Daemon not running yet, launch in background
	start_cmd = sprintf('LD_LIBRARY_PATH="" "%s" "%s" --server %d &', python_bin, py_script, port);
	system(start_cmd);
	pause(0.4);
	try
		t = tcpclient('127.0.0.1', port, 'Timeout', 30.0);
		connected = true;
	catch
		connected = false;
	end
end

if connected
	write(t, [uint8(temp_mat), uint8(10)]);	% append newline for readline

	resp = char(readline(t));
	delete(t);
	if ~contains(resp, "OK")
		error("sp_py VisPy daemon failed: %s", resp);
	end
else
	% Direct fallback execution
	cmd = sprintf('LD_LIBRARY_PATH="" "%s" "%s" "%s"', python_bin, py_script, temp_mat);
	[status, cmdout] = system(cmd);
	if status ~= 0
		error("sp_py VisPy rendering failed:\n%s", cmdout);
	end
end

end

function delete_temp_file(fpath)
	if exist(fpath, 'file')
		delete(fpath);
	end
end
