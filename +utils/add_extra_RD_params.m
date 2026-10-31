function H = add_extra_RD_params(inp)
arguments (Input)
	inp RadarData
end
arguments (Output)
	H RadarData
end
H = inp;
H.ipp_us = inp.m_fIntrPulsePeriod_us;
H.n_coh = inp.m_sNumOfCohIntegrations;
H.in_coh = inp.m_sNumOfInCohIntegrations;
H.start_height = inp.m_fWindow1StartHeight;
H.end_height = inp.m_fWindow1EndHeight;
H.nRangeBins = inp.m_sNumOfRangeBins;
H.nFFT = inp.m_sNFFT;
H.direction = Data.aoz2dir(az=inp.m_fAzimuth, oz=inp.m_fOffZenith);
H.a_params = struct();
end
