function sigma_v = compute_spectrum_broadening(z, u, v, w, v_radial, sigma_turb_base, sigma_chi)
arguments (Input)
	z (1, :) double
	u (1, :) double
	v (1, :) double
	w (1, :) double
	v_radial (1, :) double
	% base turbulance
	sigma_turb_base (1,1) double = .2
	% Intermittency severity parameter
	sigma_chi (1,1) double = 0.2;
end
arguments (Output)
	%
	sigma_v (1, :) double
end

N_gates = length(z);
dz_m = (z(2) - z(1)) * 1000; % Range gate resolution in meters

% cross-beam velocity magnitude
v_cross = sqrt(u.^2 + v.^2 + w.^2 - v_radial.^2);

% Vertical shear broadening across gate width
dv_dz = abs(gradient(v_radial, dz_m));
sigma_shear = (dv_dz .* dz_m) / sqrt(12);
% Antenna beam broadening (finite one-way beamwidth)
theta_3db = deg2rad(3.3);
sigma_beam = (theta_3db / (2 * sqrt(2 * log(2)))) * abs(v_cross);
% turbulence
sigma_turb_base = sigma_turb_base * ones(1, N_gates); % [m/s]

% Unmodulated spectral width
sigma_v_base = sqrt(sigma_shear.^2 + sigma_beam.^2 + sigma_turb_base.^2);

% Spatially Correlated Log-Normal Stochastic Process
mu_chi = -0.5 * sigma_chi^2;   % Mean-preserving offset

raw_noise = randn(1, N_gates);

% Apply Gaussian spatial smoothing filter (correlation length ~ 450 m)
corr_length_gates = round(0.45 / (z(2) - z(1)));
eta_corr = smoothdata(raw_noise, 'gaussian', max(3, corr_length_gates));
eta_corr = eta_corr / std(eta_corr); % Renormalize variance to 1

% Compute log-normal multiplier
chi = exp(mu_chi + sigma_chi * eta_corr);

% final spectrum broadening Width
sigma_v = sigma_v_base .* chi;

end
