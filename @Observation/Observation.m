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

		DBS_Factor_H (1, 1) double
		DBS_Factor_V (1, 1) double
	end

	methods
		function obj = Observation(basename)
			arguments
				basename string
			end
			raw = utils.read_raw_file(basename + ".raw");
			out = utils.add_reference_data(raw, add_mmts=true, add_uvw=true);
			[~, obj.observation_name, ~] = fileparts(basename);

			obj.north = out.beam_struct.north;
			obj.east = out.beam_struct.east;
			obj.west = out.beam_struct.west;
			obj.south = out.beam_struct.south;
			obj.vertical = out.beam_struct.vertical;
			obj.DBS_Factor_H = utils.compute_dbs_factor(obj.north.m_fOffZenith);
			obj.DBS_Factor_V = utils.compute_dbs_factor(obj.vertical.m_fOffZenith);

			obj.ref_height = out.height;
			obj.ref_U = out.U;
			obj.ref_V = out.V;
			obj.ref_W = out.W;

		end
	end
end
