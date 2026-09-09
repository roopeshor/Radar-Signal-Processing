classdef BeamHeader
	%BeamHeader - all 52 basic beam header data fields except BeamData
	% used for type checking and type hinting in some util functions
	% also its a nice abstraction when creating synthetic observations
	properties
		m_sMagicNumber               (1, 1) double  % file magic number (expected: 369)
		m_sNumOfRangeBins            (1, 1) double  % number of range bins (typical: 173)
		m_fBaudLength_us             (1, 1) double  % baud length in microseconds
		m_sNFFT                      (1, 1) double  % FFT size (number of Doppler bins) (typical: 1024)
		m_sNumOfCohIntegrations      (1, 1) double  % number of coherent integrations
		m_sNumOfInCohIntegrations    (1, 1) double  % number of incoherent integrations
		m_sCodeFlag                  (1, 1) double  % coding flag
		m_fIntrPulsePeriod_us        (1, 1) double  % inter-pulse period in microseconds
		m_fPulseWidth_us             (1, 1) double  % pulse width in microseconds
		m_sNumOfObservWindows        (1, 1) double  % number of observation windows
		m_sStationID                 (1, 1) double  % station identifier
		m_sReserved1                 (1, 1) double  % reserved field 1
		m_sReserved2                 (1, 1) double  % reserved field 2
		m_sReserved3                 (1, 1) double  % reserved field 3
		m_sYear                      (1, 1) double  % acquisition year
		m_sMonth                     (1, 1) double  % acquisition month
		m_sDay                       (1, 1) double  % acquisition day
		m_sHour                      (1, 1) double  % acquisition hour (UTC)
		m_sMin                       (1, 1) double  % acquisition minute (UTC)
		m_sSec                       (1, 1) double  % acquisition second (UTC)
		m_sReserved4                 (1, 1) double  % reserved field 4
		m_fLatitude                  (1, 1) double  % station latitude (degrees)
		m_fLongitude                 (1, 1) double  % station longitude (degrees)
		m_fAltitude                  (1, 1) double  % station altitude (m)
		m_fTotalPowerRadiated        (1, 1) double  % total radiated power (W)
		m_fRadiatedPower_ClusterWise(13, 1) double  % per-cluster radiated power
		m_sOperationMode             (1, 1) double  % operation mode index
		m_sCurrentBeamCnt            (1, 1) double  % index of this beam within the file
		m_sTotalNumberofBeams        (1, 1) double  % total number of beams in the file
		m_usCodeLength               (1, 1) double  % code length
		m_cComment                  (16, 1) char    % comment string
		m_fTRP_RF_Delay_us           (1, 1) double  % TRP/RF delay in microseconds
		m_fMGC_Gain_dB               (1, 1) double  % manual gain control value (dB)
		m_usWindowType               (1, 1) double  % window function type flag
		m_usReserved                 (1, 1) double  % reserved field
		m_cArrRemarks              (512, 1) char    % remarks string
		m_ulCodeA                    (2, 1) double  % code word A
		m_ulCodeB                    (2, 1) double  % code word B
		m_ucExperimentDataEnable     (1, 1) double  % experiment data enable flag
		m_cReserved                  (3, 1) int8    % reserved bytes
		m_fAzimuth                   (1, 1) double  % beam azimuth angle (degrees; 0=N,90=W,180=S,270=E)
		m_fOffZenith                 (1, 1) double  % off-zenith angle (degrees; 0, vertical)
		m_fWindow1StartHeight        (1, 1) double  % observation window 1 start altitude (km)
		m_fWindow1EndHeight          (1, 1) double  % observation window 1 end altitude (km)
		m_fWindow2StartHeight        (1, 1) double  % observation window 2 start altitude (km)
		m_fWindow2EndHeight          (1, 1) double  % observation window 2 end altitude (km)
		m_fWindow3StartHeight        (1, 1) double  % observation window 3 start altitude (km)
		m_fWindow3EndHeight          (1, 1) double  % observation window 3 end altitude (km)
		m_fWindow4StartHeight        (1, 1) double  % observation window 4 start altitude (km)
		m_fWindow4EndHeight          (1, 1) double  % observation window 4 end altitude (km)
		m_fWindow5StartHeight        (1, 1) double  % observation window 5 start altitude (km)
		m_fWindow5EndHeight          (1, 1) double  % observation window 5 end altitude (km)
	end

	methods
		function obj = BeamHeader(cfg)
			arguments
				cfg = struct()
			end

			% apply given data if its BeamHeader or struct
			if class(cfg) == "BeamHeader" || class(cfg) == "struct"
				bhf = properties("BeamHeader");
				for i = 1:length(bhf)
					if isfield(cfg, bhf{i}) || isprop(cfg, bhf{i})
						obj.(bhf{i}) = cfg.(bhf{i});
					end
				end
			end
		end
	end
end
