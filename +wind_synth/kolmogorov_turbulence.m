function [u_turb, v_turb, w_turb] = kolmogorov_turbulence(h, u_mean, v_mean, cfg)
arguments (Input)
	h (1, :) double % height bins
	u_mean (1, :) double % mean zonal wind profile
	v_mean (1, :) double % mean meridional wind profile
	% Kolmogorov Turbulence & Intermittency
	cfg.kt_vaf double = 0.25           % [ ] Vertical anisotropy scaling factor
	cfg.kt_bf double = 1               % [ ] Baseline factor for turbulence scaling
	cfg.kt_maxT double = 2.5           % [ ] Maximum turbulence boost under instability
	cfg.kt_Ric double = 0.25           % [ ] Critical Richardson Number Threshold
	cfg.kt_tlpeak double = 3           % [km] Turbulence layer peak altitude
	cfg.kt_vthick double = 2.5         % [km] Vertical thickness scale of turbulent layer
	cfg.turb_interm_sigma double = 0.5 % [ ] Intermittency parameter for log-normal weighting
	cfg.lw_N_bv double = 0.012         % [rad/s] Brunt-Väisälä buoyancy frequency
end
arguments (Output)
	u_turb (1, :) double
	v_turb (1, :) double
	w_turb (1, :) double
end
% Stable Kolmogorov Turbulence with Log-Normal Intermittency
z = h(:);
N = length(z);
dz = z(2) - z(1);

u_m = u_mean(:);
v_m = v_mean(:);

du_dz = gradient(u_m, dz * 1000);
dv_dz = gradient(v_m, dz * 1000);
shear_sq = du_dz.^2 + dv_dz.^2 + 1e-8;

Ri = (cfg.lw_N_bv^2) ./ shear_sq;
turb_boost = cfg.kt_bf + cfg.kt_maxT * (Ri < cfg.kt_Ric) .* exp(-((z - cfg.kt_tlpeak)/cfg.kt_vthick).^2);

k_vec = [(0:floor(N/2)), (-floor((N-1)/2):-1)]' / (N * dz);
k_min = 1 / (N * dz);
k_abs = max(abs(k_vec), k_min);

H_turb = k_abs.^(-5/6);
H_turb(1) = 0;

raw_u = real(ifft(fft(randn(N, 1)) .* H_turb));
raw_v = real(ifft(fft(randn(N, 1)) .* H_turb));
raw_w = real(ifft(fft(randn(N, 1)) .* H_turb));

norm_u = (raw_u - mean(raw_u)) / std(raw_u);
norm_v = (raw_v - mean(raw_v)) / std(raw_v);
norm_w = (raw_w - mean(raw_w)) / std(raw_w);

mu_interm = -0.5 * cfg.turb_interm_sigma^2;
interm_weight = exp(mu_interm + cfg.turb_interm_sigma * norm_u);

sigma_base = 0.15 + 0.4 * (sqrt(shear_sq) / max(sqrt(shear_sq)));
sigma_turb = sigma_base .* turb_boost .* interm_weight;

u_turb = (norm_u .* sigma_turb)';
v_turb = (norm_v .* sigma_turb)';
w_turb = (norm_w .* (sigma_turb * cfg.kt_vaf))';
end
