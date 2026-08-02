function visualize_spectra(beams, directions, options)

arguments
	beams (:, 1024, :) double
	directions (:, 1) string
	options.figsize = [2, 3] % size of figure
	options.max_velocity = 30
	options.start_height = 0 % in meters
	options.end_height = 8000 % in meters
	options.scalar function_handle = @(x) 10 * log10(x)  % scaling function
end

%VISUALIZE_SPECTRA  Plots the tile of 2D Range-Doppler power spectra.
%
%  plots denoised spectra of 5 beams in a tile.
%  Each subplot shows power in dB versus Doppler velocity (m/s) and altitude (km).
%  The function expects array of RadarData
%
%  Example:
%      % With a variable 'beams' in workspace provided to the function's scope, run:
%      visualize_spectra([beam.north, beam.south]);
%
%  See also process_beams


figure("Name", "Spectra");

for i = 1:size(beams, 3)
	beam_spectra = beams(:, :, i);

	% Calculate Power dB
	warning('off', 'MATLAB:log:logOfZero');
	power_db = options.scalar(beam_spectra);
	warning('on', 'MATLAB:log:logOfZero');

	subplot(options.figsize(1), options.figsize(2), i);

	extent_x = [-options.max_velocity, options.max_velocity];
	extent_y = [options.start_height, options.end_height];
	imagesc(extent_x, extent_y, power_db);

	title(directions(i));
	xlabel('Doppler Velocity (m/s)');
	ylabel('Altitude (km)');

	grid on;
	% In MATLAB, imagesc puts y-axis top-down by default. 'YDir', 'normal' flips it.
	set(gca, 'YDir', 'normal');
	colormap('jet');
	set(gca, 'GridColor', 'k', 'GridLineStyle', '--', 'GridAlpha', 0.3);
end
end
