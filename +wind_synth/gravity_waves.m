function [u_gw, v_gw, w_gw] = gravity_waves(h, cfg)
arguments (Input)
	h (1, :) double % height bins
	% Continuous Gravity Wave Spectrum
	cfg.gw_nmodes double = 20        % [ ] Number of continuous gravity wave spectrum modes
	cfg.gw_amp double = 2.5          % [m/s] Scaling factor for gravity wave horizontal velocity
	cfg.gw_max_lambda double = 4.0;  % [km] Upper limit for gravity wave vertical scale
	cfg.gw_damp_scale double = 12.0; % [km] Tightened damping scale (was 18.0 km) to control upper amplitude
	cfg.gw_cf double = 0.05          % [ ] Coupling factor deriving vertical wave speed from horizontal wave speed
	cfg.lw_Hs double = 7.0           % [km] Density scale height for wave amplification (e^(z / 2H_s))
end
arguments (Output)
	u_gw (1, :) double
	v_gw (1, :) double
	w_gw (1, :) double
end
% Continuous Gravity Wave Spectrum
z = h(:);
N = length(z);

m_wavenumbers = linspace(2*pi/cfg.gw_max_lambda, 2*pi/0.4, cfg.gw_nmodes)';
phases_u = rand(cfg.gw_nmodes, 1) * 2 * pi;
phases_v = rand(cfg.gw_nmodes, 1) * 2 * pi;

E_m = (m_wavenumbers).^(-1.5);
E_m = E_m / sum(E_m);

u_wave_spec = zeros(N, 1);
v_wave_spec = zeros(N, 1);
for i = 1:cfg.gw_nmodes
	u_wave_spec = u_wave_spec + sqrt(E_m(i)) * cos(m_wavenumbers(i) * z + phases_u(i));
	v_wave_spec = v_wave_spec + sqrt(E_m(i)) * sin(m_wavenumbers(i) * z + phases_v(i));
end

amp_growth = exp(z / (2 * cfg.lw_Hs)) .* exp(-z / cfg.gw_damp_scale);
u_gw = (cfg.gw_amp * (u_wave_spec / std(u_wave_spec)) .* amp_growth)';
v_gw = (cfg.gw_amp * (v_wave_spec / std(v_wave_spec)) .* amp_growth)';
w_gw = -cfg.gw_cf * u_gw;
end
