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

		ref_height (1, :) double % from uvw file
		ref_U (1, :) double
		ref_V (1, :) double
		ref_W (1, :) double

		% DBS factors [m]: scaling factor to convert Doppler frequencies (Hz) into wind velocities (m/s).
		% Horizontal DBS factor = λ/(2sin(oz))
		DBS_Factor_H (1, 1) double
		% Vertical DBS factor = λ/2
		DBS_Factor_V (1, 1) double

		f_max (1,1) double % maximum frequency deviation in the doppler spectrum
		v_max (1,1) double % maximum velocity in the doppler spectrum
	end

	methods
		function obs = Observation(stuff)
			arguments
				stuff = ''
			end
			is_str = isa(stuff, "string") || isa(stuff, "char");
			if nargin == 0 || (is_str && stuff == "")
				% nothing is given, probably instantiated from readers or util functions
				return;
			end
			if is_str
				% given is filepath, use a file reader
				stuff = char(stuff);
				if (stuff(end-3:end) == ".raw")
					% already is pointing to raw
					obs.raw_filepath = stuff;
				else
					obs.raw_filepath = stuff + ".raw";
				end

				raw      = utils.read_raw_file(obs.raw_filepath);
				ref_data = utils.add_reference_data(raw, obs.raw_filepath, add_mmts=true, add_uvw=true);

				obs.north    = ref_data.beam_struct.north;
				obs.east     = ref_data.beam_struct.east;
				obs.west     = ref_data.beam_struct.west;
				obs.south    = ref_data.beam_struct.south;
				obs.vertical = ref_data.beam_struct.vertical;

				obs.ref_height = ref_data.height;
				obs.ref_U = ref_data.U;
				obs.ref_V = ref_data.V;
				obs.ref_W = ref_data.W;

			elseif isa(stuff, "RadarData") && length(stuff) == 5
				% Has already given raw data, probably from synthetic data constructor
				for k = 1:5
					obs.(stuff(k).direction) = stuff(k);
				end
			else
				warning("No suitable input data found")
				return;
			end

			vel_factor = 3.0e8 / 205e6 / 2.0;
			obs.DBS_Factor_V = vel_factor;
			obs.DBS_Factor_H = vel_factor / (2 * sind(obs.north.m_fOffZenith));

			obs.f_max = utils.compute_max_freq(obs.north.ipp_us, obs.north.n_coh);
			obs.v_max = obs.f_max * vel_factor; % DBS_V
		end
	end
end
