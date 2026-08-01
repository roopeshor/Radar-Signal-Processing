function structure = process_beams(beams, options)
% process_beams packages given beams from read_raw_data into a struct with 5 direction fields
% and adds spectra property to each beam computed from compute_spectra_from_beam_data
% Also adds moments data from corresponding moments file (if exists)
%   Input Arguments:
%       beams - array of beams from read_raw_data

arguments
	beams (5, 1) RadarData
	options.add_mmts logical = false
	options.mmts_fileext = struct(...
		"vertical", "_Beam1_W1_Az_0.00_Oz_0.00", ...
		"west"    , "_Beam2_W1_Az_90.00_Oz_10.00", ...
		"east"    , "_Beam3_W1_Az_270.00_Oz_10.00", ...
		"south"   , "_Beam4_W1_Az_180.00_Oz_10.00", ...
		"north"   , "_Beam5_W1_Az_0.00_Oz_10.00" ...
	)
end

structure = struct( ...
	"vertical", RadarData(), ...
	"north", RadarData(), ...
	"west", RadarData(), ...
	"south", RadarData(), ...
	"east", RadarData() ...
	);

for i = 1:5
	beam = beams(i);
	direction = beam.direction;
	spectra = compute_spectra_from_beam_data(beam.BeamData);

	if options.add_mmts
		[fl, fn, ~] = fileparts(beam.filepath);
		fn = fullfile(fl, fn + options.mmts_fileext.(direction) +".mmts");
		[height, M0, M1, M2, SNR, noise_level] = read_mmts(fn);
		beam.ref_height = height;
		beam.ref_M0 = M0;
		beam.ref_M1 = M1;
		beam.ref_M2 = M2;
		beam.ref_SNR = SNR;
		beam.ref_noise_level = noise_level;
	end
	beam.spectra = spectra;
	structure.(direction) = beam;
end
end
