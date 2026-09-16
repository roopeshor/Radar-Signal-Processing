function [u, v, w, V_radial, spectra_all, vel_axis, altitudes] = compute_uvw(obs)
% IME.COMPUTE_UVW Orchestrates the IME pipeline across all beams of an Observation to retrieve UVW.

arguments (Input)
	% Observation object containing all 5 DBS beams.
	obs Observation
end
arguments (Output)
	% Zonal wind velocity profile (m/s) across range bins.
	u (1, :) double
	% Meridional wind velocity profile (m/s) across range bins.
	v (1, :) double
	% Vertical wind velocity profile (m/s) across range bins.
	w (1, :) double
	% 5 x RangeBins matrix of radial velocities (V, N, E, S, W).
	V_radial (5, :) double
	% 5 x 1 cell array of beam spectra matrices.
	spectra_all (5, 1) cell
	% 1 x NFFT Doppler velocity axis in m/s.
	vel_axis (1, :) double
	% Range bin altitude vector in meters.
	altitudes (1, :) double
end

obs = utils.fill_spectras(obs, @ime.compute_spectra);
obs = utils.fill_moments(obs, @ime.compute_moments);

N = obs.north;
S = obs.south;
E = obs.east;
W = obs.west;
V = obs.vertical;

numRangeBins = N.m_sNumOfRangeBins;
vel_factor = obs.DBS_Factor_V;

V_N = - N.M1 * vel_factor;
V_S = - S.M1 * vel_factor;
V_E = - E.M1 * vel_factor;
V_W = - W.M1 * vel_factor;
V_V = - V.M1 * vel_factor;

theta = deg2rad(N.m_fOffZenith);

u = (V_E - V_W) ./ (2 * sin(theta));
v = (V_N - V_S) ./ (2 * sin(theta));
w = V_V;

V_radial = [V_V; V_N; V_E; V_S; V_W];
spectra_all = {V.spectra; N.spectra; E.spectra; S.spectra; W.spectra};

vel_axis = utils.compute_velocity_axis(N);
delta_R = 299792458 * N.m_fBaudLength_us * 1e-6 / 2;
altitudes = (0:(numRangeBins-1)) * delta_R;
end
