function f_max = compute_max_freq(ipp, coh)
	%compute_max_freq  Compute the Nyquist (unambiguous) Doppler frequency for a radar beam.

	arguments (Input)
		% Inter-Pulse Period in microseconds (from Header.m_fIntrPulsePeriod_us).
		ipp (1,1) double
		% Number of coherent integrations (from Header.m_sNumOfCohIntegrations).
		coh (1,1) double = 1
	end
	arguments (Output)
		% Maximum unambiguous Doppler frequency (Hz).
		f_max (1,1) double
	end
	effective_sampling_time = ipp * 1e-6 * coh;
	f_max = 1 / (2.0 * effective_sampling_time);
end
