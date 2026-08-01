classdef Observation
	% Observation  Value class representing all given data in observation.
	%
	% Each beam headers are present in north, east, west, south and vertical properties
	% Reference data "ref_..." are obtained from uvw file.
	% The height data is obtained from the uvw file.
	% Moments references are put in each beam, see RadarData class.
	% To use this class, instantiate the class with base name of the observation files
	% all raw, uvw, mmts will be automatically found and data will be extracted
	properties
		north RadarData
		east RadarData
		west RadarData
		south RadarData
		vertical RadarData

		observation_name string

		ref_height (:, 1) double % from uvw file
		ref_U (:, 1) double
		ref_V (:, 1) double
		ref_W (:, 1) double

	end

	methods
		function obj = Observation(basename)
			arguments
				basename string
			end
			beams = process_beams(read_raw_file(basename + ".raw"), add_mmts=true);
			[~, obj.observation_name, ~] = fileparts(basename);

			obj.north = beams.north;
			obj.east = beams.east;
			obj.west = beams.west;
			obj.south = beams.south;
			obj.vertical = beams.vertical;

			[obj.ref_height, obj.ref_U, obj.ref_V, obj.ref_W] = read_uvw(basename + "_W1.uvw");

		end
	end
end
