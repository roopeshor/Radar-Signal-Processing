function f_max = compute_max_freq(ipp, coh)
	%compute_max_freq  Compute the Nyquist (unambiguous) Doppler frequency for a radar beam.
	%
	%   Input Arguments:
	%     ipp   - Inter-Pulse Period in microseconds
	%             (from Header.m_fIntrPulsePeriod_us).
	%     coh - Number of coherent integrations (default: 1)
	%             (from Header.m_sNumOfCohIntegrations).
	%
	%   Output Arguments:
	%     f_max - Maximum unambiguous Doppler frequency (Hz).

	arguments (Input)
		ipp (1,1) double % Inter Pulse Period in microseconds
		coh (1,1) double = 1 % number of coherent integrations
	end
	arguments (Output)
		f_max (1,1) double
	end
	effective_sampling_time = ipp * 1e-6 * coh;
	f_max = 1 / (2.0 * effective_sampling_time);
end
