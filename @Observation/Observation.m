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
				basename string = ""
			end
			if nargin == 0 || basename == ""
				return;
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

	methods (Static)
		function obj = synthetic(basename, u, v, w, config)
			% synthetic  Create an artificial raw data file from a wind velocity array.
			%   obj = Observation.synthetic(basename, u, v, w)
			%   Generates a synthetic ST Radar raw data file (basename.raw) using
			%   the Zrnic method to synthesize I/Q time-series data. If basename is not empty,
			%   it will store the synthetic data to a file.

			arguments
				basename string
				u (:, 1) double
				v (:, 1) double
				w (:, 1) double
				config.nRangeBins double = 173
				config.PRF double = 16000;
				config.NCI double = 256;
				config.NFFT double = 1024;
				config.StartHeight double = 315;
				config.BaudLength double = 0.3; % us
			end

			lambda = 3e8 / 205e6;
			nRangeBins = config.nRangeBins;
			PRF = config.PRF;
			NCI = config.NCI;
			NFFT = config.NFFT;
			PRF_eff = PRF / NCI;
			StartHeight = config.StartHeight;
			BaudLength = config.BaudLength;

			heights = Observation.compute_height_ranges(StartHeight, nRangeBins, BaudLength);
			EndHeight = heights(end);

			% SNR profile (exponentially decaying linear power -> linearly decaying dB)
			SNR_dB = linspace(20, -10, nRangeBins)';

			% Noise power in digital units (variance)
			% Scaled to allow storage as int32 with sufficient resolution
			Pn_digital = 1000;

			% Beam definitions (Vertical, East, West, North, South)
			beam_az = [0, 90, 270, 0, 180];
			beam_oz = [0, 10, 10, 10, 10];

			% Initialize Header array
			Header(5) = RadarData();
			for k = 1:5
				% Standard header fields
				Header(k).m_sMagicNumber = 369;
				Header(k).m_sNumOfRangeBins = int16(nRangeBins);
				Header(k).m_fBaudLength_us = single(BaudLength);
				Header(k).m_sNFFT = int16(NFFT);
				Header(k).m_sNumOfCohIntegrations = NCI;
				Header(k).m_sNumOfInCohIntegrations = 1;
				Header(k).m_fIntrPulsePeriod_us = 1e6 / PRF;
				Header(k).m_fPulseWidth_us = single(BaudLength);
				Header(k).m_sNumOfObservWindows = 1;
				Header(k).m_fWindow1StartHeight = single(StartHeight);
				Header(k).m_fWindow1EndHeight = single(EndHeight);
				Header(k).m_fAzimuth = beam_az(k);
				Header(k).m_fOffZenith = beam_oz(k);
				Header(k).m_sTotalNumberofBeams = 5;
				Header(k).m_sCurrentBeamCnt = k;
				Header(k).m_usCodeLength = 16;
				Header(k).m_fTotalPowerRadiated = 10000;

				% other params
				Header(k).filepath = basename + ".raw";
				Header(k).direction = utils.get_beam_direction(beam_az(k), beam_oz(k));
				Header(k).ipp_us = Header(k).m_fIntrPulsePeriod_us;
				Header(k).n_coh = Header(k).m_sNumOfCohIntegrations;
				Header(k).start_height = Header(k).m_fWindow1StartHeight;
				Header(k).end_height = Header(k).m_fWindow1EndHeight;

				% Radial velocity projection
				vr = Observation.compute_radial_velocity(u, v, w, beam_az(k), beam_oz(k));

				% IQ synthesis
				Header(k).BeamData = Observation.synthesize_iq_data(vr, lambda, PRF_eff, NFFT, Pn_digital, SNR_dB);
			end

			% Write to file
			filepath = basename + ".raw";
			utils.write_raw_file(Header, filepath);

			% Populate Observation object directly
			obj = Observation();
			[~, obj.observation_name, ~] = fileparts(basename);

			for k = 1:5
				az = Header(k).m_fAzimuth;
				oz = Header(k).m_fOffZenith;
				if oz == 0
					obj.vertical = Header(k);
				elseif az == 0
					obj.north = Header(k);
				elseif az == 90
					obj.east = Header(k);
				elseif az == 180
					obj.south = Header(k);
				elseif az == 270
					obj.west = Header(k);
				end
			end

			obj.DBS_Factor_H = utils.compute_dbs_factor(10);
			obj.DBS_Factor_V = utils.compute_dbs_factor(0);

			obj.ref_height = heights;
			obj.ref_U = u;
			obj.ref_V = v;
			obj.ref_W = w;
		end
	end

	methods (Access = private, Static)
		function heights = compute_height_ranges(start_height, nBins, baud_length_us)
			range_res = 3e8 * (baud_length_us * 1e-6) / 2; % meters
			heights = start_height + (0:nBins-1)' * range_res;
		end

		function vr = compute_radial_velocity(u, v, w, az, oz)
			theta = oz * pi / 180;
			phi   = az * pi / 180;
			vr = u .* sin(phi) .* sin(theta) + ...
				 v .* cos(phi) .* sin(theta) + ...
				 w .* cos(theta);
		end

		function BeamData = synthesize_iq_data(vr, lambda, PRF_eff, NFFT, Pn_digital, SNR_dB)
			nRangeBins = length(vr);
			BeamData = zeros(nRangeBins, NFFT, 1);

			fd = -2 * vr / lambda;
			f = linspace(-PRF_eff/2, PRF_eff/2 - PRF_eff/NFFT, NFFT);
			sigma_v = 1.0; % 1 m/s spectral width
			sigma_f = 2 * sigma_v / lambda;

			for z = 1:nRangeBins
				Ps_digital = Pn_digital * 10^(SNR_dB(z)/10);

				% Signal spectrum
				S_sig = exp(-(f - fd(z)).^2 / (2 * sigma_f^2));
				if sum(S_sig) > 0
					S_sig = S_sig / sum(S_sig) * Ps_digital;
				else
					S_sig = zeros(1, NFFT);
				end

				S_noise = (Pn_digital / NFFT) * ones(1, NFFT);
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
