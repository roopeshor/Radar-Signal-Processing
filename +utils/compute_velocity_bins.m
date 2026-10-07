function vel_axis = compute_velocity_bins(nfft, ipp, in_coh)
% UTILS.compute_velocity_bins Calculates the 1D Doppler velocity axis (m/s) for a radar beam.
%
%   Evaluates Doppler frequencies fd = (-NFFT/2 : NFFT/2-1) / (NFFT * effective_PRI)
%   and converts to radial velocity v = - lambda * fd / 2.

arguments (Input)
	% BeamHeader or RadarData beam object.
	nfft (1, 1) double % number of FFT points
	ipp (1, 1) double % m_fIntrPulsePeriod_us
	in_coh (1, 1) double % number of incoherent integration
end
arguments (Output)
	% 1 x NFFT vector of Doppler velocities (m/s).
	vel_axis (1, :) double
end

c = 299792458;
fc = 205e6;
lambda = c / fc;

effective_PRI = ipp * 1e-6 * in_coh;

fd = (-nfft/2 : nfft/2 - 1) / (nfft * effective_PRI);
vel_axis = -lambda * fd / 2;
end
