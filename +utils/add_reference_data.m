function out = add_reference_data(beams, options)
% add_reference_data packages moments file corresponding to each beam with RadarData from read_raw_data.
% Also returns UVW data from corresponding UVW file (if exists)
%   Input Arguments:
%       beams - array of beams from read_raw_data

arguments (Input)
	beams (5, 1) RadarData
	options.add_mmts = true
	options.add_uvw = true
	options.uvw_file_ext = "_W1.uvw"
	options.mmts_file_ext = struct(...
		"vertical", "_Beam1_W1_Az_0.00_Oz_0.00.mmts", ...
		"west"    , "_Beam2_W1_Az_90.00_Oz_10.00.mmts", ...
		"east"    , "_Beam3_W1_Az_270.00_Oz_10.00.mmts", ...
		"south"   , "_Beam4_W1_Az_180.00_Oz_10.00.mmts", ...
		"north"   , "_Beam5_W1_Az_0.00_Oz_10.00.mmts" ...
		)
end
arguments (Output)
	out (1,1) struct
end

%% moments
beam_struct = struct( ...
	"vertical", RadarData(), ...
	"north", RadarData(), ...
	"west", RadarData(), ...
	"south", RadarData(), ...
	"east", RadarData() ...
	);

[folder, basename, ~] = fileparts(beams(1).filepath);
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

	%% UVW
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
