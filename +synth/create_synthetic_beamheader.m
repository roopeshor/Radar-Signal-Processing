function H = create_synthetic_beamheader(config)
% synth.create_synthetic_beamheader Generates a synthetic BeamHeader object for simulation and testing.
%
%   Constructs default 52-field radar header structures configured for lower (tropospheric),
%   middle (stratospheric), or upper altitude modes, with optional custom property overrides.

arguments (Input)
	% Custom header property overrides (struct or BeamHeader).
	config.headerFields = struct()
	% Altitude mode configuration selector ("lower", "middle", "upper").
	config.altitudeRange string = "lower"
end
arguments (Output)
	% Synthesized BeamHeader object.
	H BeamHeader
end

H = BeamHeader();

H.m_sMagicNumber               = 369;
H.m_sNFFT                      = 1024;
H.m_sNumOfInCohIntegrations    = 1;
H.m_sCodeFlag                  = 0;
H.m_sNumOfObservWindows        = 1;
H.m_sStationID                 = 101;
H.m_sReserved1                 = 0;
H.m_sReserved2                 = 0;
H.m_sReserved3                 = 0;
H.m_sReserved4                 = 0;
H.m_fLatitude                  = 10.039999961853;
H.m_fLongitude                 = 76.3300018310547;
H.m_fAltitude                  = 34;
H.m_fTotalPowerRadiated        = 0;
H.m_fRadiatedPower_ClusterWise = [0 0 0 0 0 0 0 0 0 0 0 0 0];
H.m_sOperationMode             = 0;
H.m_sTotalNumberofBeams        = 5;
H.m_cComment                   = repelem(" ", 16)';
H.m_fTRP_RF_Delay_us           = 2.09999990463257;
H.m_fMGC_Gain_dB               = 30;
H.m_usWindowType               = 3;
H.m_usReserved                 = 0;
H.m_ucExperimentDataEnable     = 1;
H.m_cReserved                  = [0 0 0];
H.m_fWindow2StartHeight        = 0;
H.m_fWindow2EndHeight          = 0;
H.m_fWindow3StartHeight        = 0;
H.m_fWindow3EndHeight          = 0;
H.m_fWindow4StartHeight        = 0;
H.m_fWindow4EndHeight          = 0;
H.m_fWindow5StartHeight        = 0;
H.m_fWindow5EndHeight          = 0;
H.m_sCurrentBeamCnt            = 0;

ArrMark_pad = repelem(" ", 512-8);
switch config.altitudeRange
	case "lower"
		H.m_sNumOfRangeBins = 173;
		H.m_fBaudLength_us = 0.300000011920929;
		H.m_sNumOfCohIntegrations = 256;
		H.m_fIntrPulsePeriod_us = 62.5000038146973;
		H.m_fPulseWidth_us = 0.300000011920929;
		H.m_usCodeLength = 1;
		arrRem = split("0p3_30Hz", '')';
		H.m_cArrRemarks = [arrRem(2:end-1),  ArrMark_pad];
		H.m_ulCodeA = [1 4294967295];
		H.m_ulCodeB = [1 4294967295];
		H.m_fWindow1StartHeight = 315;
		H.m_fWindow1EndHeight = 8100;
	case "middle"
		H.m_sNumOfRangeBins = 94;
		H.m_fBaudLength_us = 1.20000004768372;
		H.m_sNumOfCohIntegrations = 100;
		H.m_fIntrPulsePeriod_us = 161.290328979492;
		H.m_fPulseWidth_us = 19.2000007629395;
		H.m_usCodeLength = 16;
		arrRem = split("1p2_30Hz", '')';
		H.m_cArrRemarks = [arrRem(2:end-1), ArrMark_pad];
		H.m_ulCodeA = [60898 4294967295];
		H.m_ulCodeB = [60701 4294967295];
		H.m_fWindow1StartHeight = 3150;
		H.m_fWindow1EndHeight = 20000;
	otherwise
		H.m_sNumOfRangeBins = 73;
		H.m_fBaudLength_us = 2.40000009536743;
		H.m_sNumOfCohIntegrations = 64;
		H.m_fIntrPulsePeriod_us = 263.157897949219;
		H.m_fPulseWidth_us = 38.4000015258789;
		H.m_usCodeLength = 16;
		arrRem = split("2p4_30Hz", '')';
		H.m_cArrRemarks = [arrRem(2:end-1), ArrMark_pad];
		H.m_ulCodeA = [60898 4294967295];
		H.m_ulCodeB = [60701 4294967295];
		H.m_fWindow1StartHeight = 6030;
		H.m_fWindow1EndHeight = 32000;
end

bhf = properties(H);
for i = 1:length(bhf)
	if (isfield(config.headerFields, bhf{i}) || isprop(config.headerFields, bhf{i}))
		H.(bhf{i}) = config.headerFields.(bhf{i});
	end
end

if (H.m_sCurrentBeamCnt == 0); H.m_fOffZenith = 0;
else; H.m_fOffZenith = 10; end

H.m_fAzimuth = Data.cnt2az(H.m_sCurrentBeamCnt);
end
