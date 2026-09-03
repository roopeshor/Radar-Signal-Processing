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

		DBS_Factor_H (1, 1) double
		DBS_Factor_V (1, 1) double
	end

	methods
		function obj = Observation(stuff)
			arguments
				stuff = ""
			end
			is_str = class(stuff) == "string" || class(stuff) == "char";
			if nargin == 0 || (is_str && stuff == "")
				return;
			end
			if is_str
				obj.raw_filepath = stuff + ".raw";

				raw              = utils.read_raw_file(obj.raw_filepath);
				ref_data         = utils.add_reference_data(raw, obj.raw_filepath, add_mmts=true, add_uvw=true);

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
					az = stuff(k).m_fAzimuth;
					oz = stuff(k).m_fOffZenith;
					if oz == 0
						obj.vertical = stuff(k);
					elseif az == 0
						obj.north = stuff(k);
					elseif az == 90
						obj.east = stuff(k);
					elseif az == 180
						obj.south = stuff(k);
					elseif az == 270
						obj.west = stuff(k);
					end
				end
			else
				warning("No suitable input data found")
			end
			obj.DBS_Factor_H = utils.compute_dbs_factor(obj.north.m_fOffZenith);
			obj.DBS_Factor_V = utils.compute_dbs_factor(obj.vertical.m_fOffZenith);
		end
	end

	methods (Static)
		function obj = synthetic(u, v, w, config)
			% synthetic  Create an artificial raw data file from a wind velocity array.
			%   obj = Observation.synthetic(u, v, w)
			%   Generates a synthetic ST Radar raw data
			%   the Zrnic method to synthesize I/Q time-series data. If basename is not empty,
			%   it will store the synthetic data to a file.

			arguments
				u (:, 1) double
				v (:, 1) double
				w (:, 1) double
				config.headerFields struct = struct()

				% filepath to write observation in a .raw file. Observation be written to file if this is empty string
				config.filepath string = ""
			end

			Headers = RadarData.empty(0, 5);
			for k = 1:5
				config.headerFields.m_sCurrentBeamCnt = k - 1;

				H = utils.create_headers(headerFields=config.headerFields);
				vr = utils.compute_radial_velocity(u, v, w, H.m_fAzimuth, H.m_fOffZenith);

				Headers(k) = RadarData(H);
				Headers(k).BeamData = Observation.synthesize_iq_data(vr, H);
			end

			% Write to file
			if (config.filepath ~= "")
				utils.write_raw_file(Headers, config.filepath);
			end

			obj = Observation(Headers);

			range_res = 3e8 * (H.m_fBaudLength_us * 1e-6) / 2; % meters
			obj.ref_height = H.m_fWindow1StartHeight + (0:H.m_sNumOfRangeBins-1)' * range_res;
			obj.ref_U = u;
			obj.ref_V = v;
			obj.ref_W = w;
		end
	end

	methods (Access = private, Static)
		function BeamData = synthesize_iq_data(vr, H)
			arguments
				% radial velocity
				vr (:, 1) double

				% header data to get some info
				H BeamHeader
			end

			NFFT = H.m_sNFFT;
			nRangeBins = H.m_sNumOfRangeBins;
			lambda = 3e8 / 205e6;
			P_noise = 1000;                           % Noise power in digital units (variance)
			fd         = -2 * vr / lambda;
			PRF_eff    = (1 / H.m_fIntrPulsePeriod_us);
			sigma_v    = 1.0;                            % 1 m/s spectral width
			sigma_f    = 2 * sigma_v / lambda;

			f      = linspace(-PRF_eff/2, PRF_eff/2 - PRF_eff/NFFT, NFFT);
			SNR_dB = linspace(20, -10, nRangeBins)';
			BeamData = zeros(nRangeBins, NFFT, 1);


			for z = 1:nRangeBins
				P_sig = P_noise * 10^(SNR_dB(z)/10);

				S_sig = exp(-(f - fd(z)).^2 / (2 * sigma_f^2));
				if sum(S_sig) > 0
					S_sig = S_sig / sum(S_sig) * P_sig;
				else
					S_sig = zeros(1, NFFT);
				end

				S_noise = (P_noise / NFFT) * ones(1, NFFT);
				S = S_sig + S_noise;

				% Zrnic method
				X = randn(1, NFFT);
				Y = randn(1, NFFT);
				Z = sqrt(S/2) .* (X + 1i * Y);

				% Time series
				s = conj(ifft(ifftshift(Z)) * sqrt(NFFT));
				BeamData(z, :, 1) = s;
			end
			% Convert to int32 range
			BeamData = round(BeamData);
		end
	end
end
