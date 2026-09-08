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

		raw_filepath string

		ref_height (:, 1) double % from uvw file
		ref_U (:, 1) double
		ref_V (:, 1) double
		ref_W (:, 1) double

		% Horizontal DBS factor = c/(4f sin(oz))
		DBS_Factor_H (1, 1) double
		% Vertical DBS factor = c/(2f)
		DBS_Factor_V (1, 1) double

        f_max (1,1) double % maximum frequency deviation in the doppler spectrum
        v_max (1,1) double % maximum velocity in the doppler spectrum
	end

	methods
		function obj = Observation(stuff)
			arguments
				stuff = ""
			end
			is_str = isa(stuff, "string") || isa(stuff, "char");
			if nargin == 0 || stuff == ""
				return;
			end
			if is_str
				obj.raw_filepath = stuff + ".raw";

				raw      = utils.read_raw_file(obj.raw_filepath);
				ref_data = utils.add_reference_data(raw, obj.raw_filepath, add_mmts=true, add_uvw=true);

				obj.north    = ref_data.beam_struct.north;
				obj.east     = ref_data.beam_struct.east;
				obj.west     = ref_data.beam_struct.west;
				obj.south    = ref_data.beam_struct.south;
				obj.vertical = ref_data.beam_struct.vertical;

				obj.ref_height = ref_data.height;
				obj.ref_U = ref_data.U;
				obj.ref_V = ref_data.V;
				obj.ref_W = ref_data.W;
			elseif isa(stuff, "RadarData") && length(stuff) == 5
				for k = 1:5
					obj.(stuff(k).direction) = stuff(k);
				end
			else
				warning("No suitable input data found")
			end
			obj.DBS_Factor_H = utils.compute_dbs_factor(obj.north.m_fOffZenith);
			obj.DBS_Factor_V = utils.compute_dbs_factor(obj.vertical.m_fOffZenith);
            obj.f_max = utils.compute_max_freq(obj.north.ipp_us, obj.north.n_coh);
			wavelength = 3.0e8 / 205e6;
            obj.v_max = obj.f_max * wavelength / 2;
		end
	end
end
