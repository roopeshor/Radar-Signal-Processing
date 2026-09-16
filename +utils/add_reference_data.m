function out = add_reference_data(beams, filepath, options)
% UTILS.ADD_REFERENCE_DATA Attaches benchmark reference moments (.mmts) and UVW wind profiles (.uvw) to radar beams.
%
%   Parses reference text files matching the observation base filename, populating reference moment fields
%   (ref_M0, ref_M1, ref_M2, ref_SNR, ref_noise_level) on each beam and extracting reference wind vectors (U, V, W).

arguments (Input)
	% 5 x 1 array of RadarData beam objects.
	beams (5, 1) RadarData
	% Base filepath of observation (with or without extension).
	filepath string
	% Flag to enable loading .mmts reference moment files.
	options.add_mmts = true
	% Flag to enable loading .uvw reference wind files.
	options.add_uvw = true
	% Extension suffix for UVW reference file.
	options.uvw_file_ext = "_W1.uvw"
	% Mapping from direction label to .mmts filename extension.
	options.mmts_file_ext = Data.dir2mmts_file_ext
end
arguments (Output)
	% Struct containing beam_struct, reference U, V, W wind vectors, and height array.
	out (1,1) struct
end

beam_struct = struct( ...
	"vertical", RadarData(), ...
	"north", RadarData(), ...
	"west", RadarData(), ...
	"south", RadarData(), ...
	"east", RadarData() ...
	);

[folder, basename, ~] = fileparts(filepath);
for i = 1:5
	beam = beams(i);
	direction = beam.direction;
	if options.add_mmts
		path = fullfile(folder, basename + options.mmts_file_ext.(direction));
		if ~isfile(path)
			warning(path + " not found, returning empty array");
			beam.ref_height = [];
			beam.ref_M0 = [];
			beam.ref_M1 = [];
			beam.ref_M2 = [];
			beam.ref_SNR = [];
			beam.ref_noise_level = [];
		else
			output = readtable( ...
				path, ...
				FileType='text', ...
				VariableNamingRule='preserve' ...
				);
			beam.ref_height = output.("Height (km)");
			beam.ref_M0 = output.("M0 Total Power(dBm)");
			beam.ref_M1 = output.("M1 Mean Doppler (Hz)");
			beam.ref_M2 = output.("M2 Doppler Spread (Hz)");
			beam.ref_SNR = output.("SNR (dB)");
			beam.ref_noise_level = output.("Noise Level (dBm)");

		end
		beam_struct.(direction) = beam;
	end

	height = [];
	U = [];
	V = [];
	W = [];
	path = fullfile(folder, basename + options.uvw_file_ext);
	if options.add_uvw
		if ~isfile(path)
			warning(path + " not found, returning empty array");
		else
			output = readtable( ...
				path, ...
				FileType='text', ...
				VariableNamingRule='preserve' ...
				);
			height = output.("Height (km)");
			U = output.("Zonal(U) (m/s)");
			V = output.("Meridional(V) (m/s)");
			W = output.("Vertical (W) (m/s)");
		end
	end
	out = struct(...
		"beam_struct", beam_struct,...
		"U", U,...
		"V", V,...
		"W", W,...
		"height", height ...
		);
end
