classdef RadarData
	% RadarData  Value class representing one beam's header and IQ data.
	%
	%   Each instance holds the 1024-byte binary header fields parsed by
	%   read_raw_file, the raw complex IQ BeamData cube, and optional
	%   post-processing fields populated by process_beams.
	%   See also read_raw_file, process_beams, compute_spectra_from_beam_data

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

		% ------------- Raw IQ data ---------------------------------------
		BeamData               (:, 1024, :) double  % double complex (RangeBins × NFFT × InCohIntegrations)

		% ---- aliases -------------
		ipp_us                        (1,1) double  % m_fIntrPulsePeriod_us
		n_coh                         (1,1) double  % m_sNumOfInCohIntegrations
		start_height                  (1,1) double  % m_fWindow1StartHeight
		end_height                    (1,1) double  % m_fWindow1EndHeight


		% --- Post-processing fields (populated by processRawFile) ---------
		direction                           string  % beam direction label (vertical/north/south/west/east)
		spectra                   (:, 1024) double  % double (RangeBins × NFFT) - averaged normalised power spectrum
		denoised_spectra          (:, 1024) double  % double (RangeBins × NFFT) - denoised power spectrum. Its absent in read_raw_data

		% ---- reference data ---------
		filepath                            string  % filepath of raw data
		ref_height                (:, 1)    double  % given height of reference
		ref_M0                    (:, 1)    double  % refernce 0th moment
		ref_M1                    (:, 1)    double  % refernce 1st moment
		ref_M2                    (:, 1)    double  % refernce 2nd moment
		ref_SNR                   (:, 1)    double  % given SNR
		ref_noise_level           (:, 1)    double  % given noise level
	end
end
