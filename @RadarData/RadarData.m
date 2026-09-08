classdef RadarData < BeamHeader
	% RadarData  class representing one beam's header and IQ data along with given reference data.
	%
	%   Each instance holds the 1024-byte binary header fields parsed by
	%   read_raw_file, the raw complex IQ BeamData cube, and optional
	%   post-processing and reference fields

	properties
		% ------------- Raw IQ data ---------------------------------------
		BeamData       (:, 1024, :) double  % size: (RangeBins × NFFT × InCohIntegrations)

		% ---- aliases -------------
		ipp_us                (1,1) double  % m_fIntrPulsePeriod_us
		n_coh                 (1,1) double  % m_sNumOfCohIntegrations
		start_height          (1,1) double  % m_fWindow1StartHeight
		end_height            (1,1) double  % m_fWindow1EndHeight


		% --- Post-processing fields ---------
		direction                   string  % beam direction label (vertical/north/south/west/east)
		spectra           (:, 1024) double  % double (RangeBins × NFFT) - averaged normalised power spectrum
		denoised_spectra  (:, 1024) double  % double (RangeBins × NFFT) - denoised power spectrum. Its absent in read_raw_data
		M0                   (1, :) double
		M1                   (1, :) double
		M2                   (1, :) double
		SNR                  (1, :) double
		noise_level          (1, :) double

		algorithm_parameters        struct  % struct to store algorithm specific parameters like cost function scores

		% ---- reference data ---------
		ref_height           (1, :) double  % given height in the measurement
		ref_M0               (1, :) double  % refernce 0th moment
		ref_M1               (1, :) double  % refernce 1st moment
		ref_M2               (1, :) double  % refernce 2nd moment
		ref_SNR              (1, :) double  % given SNR
		ref_noise_level      (1, :) double  % given noise level
	end
	methods
		function obj = RadarData(cfg)
			% it first constructs beam headers and then applies rest of things
			arguments
				cfg = struct()
			end
			obj = obj@BeamHeader(cfg)
			obj.ipp_us = obj.m_fIntrPulsePeriod_us;
			obj.n_coh = obj.m_sNumOfCohIntegrations;
			obj.start_height = obj.m_fWindow1StartHeight;
			obj.end_height = obj.m_fWindow1EndHeight;
			obj.direction = Data.aoz2dir(az=obj.m_fAzimuth, oz=obj.m_fOffZenith);
		end
	end
end
