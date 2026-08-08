function max_velocity = compute_max_velocity(ipp, incoh)
	%COMPUTE_MAX_VELOCITY  Compute the Nyquist (unambiguous) Doppler velocity for a radar beam.
	%
	%   Input Arguments:
	%     ipp   - Inter-Pulse Period in microseconds
	%             (from Header.m_fIntrPulsePeriod_us).
	%     incoh - Number of incoherent integrations (default: 1)
	%             (from Header.m_sNumOfInCohIntegrations).
	%
	%   Output Arguments:
	%     max_velocity - Maximum unambiguous Doppler velocity (m/s).

	arguments
		ipp (1,1) double % Inter Pulse Period in microseconds
		incoh (1,1) double = 1 % number of incoherent integrations
	end
	radarFreq = 205e6;
	c = 299792458.0;
	wavelength = c / radarFreq;
	effective_sampling_time = ipp * 1e-6 * incoh;
	max_velocity = wavelength / (4.0 * effective_sampling_time);
end
