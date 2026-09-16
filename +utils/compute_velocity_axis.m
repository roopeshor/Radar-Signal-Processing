function vel_axis = compute_velocity_axis(beam)
% UTILS.COMPUTE_VELOCITY_AXIS Calculates the 1D Doppler velocity axis (m/s) for a radar beam.
%
%   Evaluates Doppler frequencies fd = (-NFFT/2 : NFFT/2-1) / (NFFT * effective_PRI)
%   and converts to radial velocity v = - lambda * fd / 2.

arguments (Input)
	% BeamHeader or RadarData beam object.
	beam BeamHeader
end
arguments (Output)
	% 1 x NFFT vector of Doppler velocities (m/s).
	vel_axis (1, :) double
end

c = 299792458;
fc = 205e6;
lambda = c / fc;
nfft = beam.m_sNFFT;

PRI = beam.m_fIntrPulsePeriod_us * 1e-6;
Ncoh = beam.m_sNumOfCohIntegrations;
effective_PRI = PRI * Ncoh;

fd = (-nfft/2 : nfft/2 - 1) / (nfft * effective_PRI);
vel_axis = -lambda * fd / 2;
end
