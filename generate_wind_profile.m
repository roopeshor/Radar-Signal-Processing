function [z, u, v, w] = generate_wind_profile(cfg)

arguments
    cfg.dz double = 0.15       % [km] range bin resolution
    cfg.max_height double = 32 % [km] max height for which wind profile has to be generated

    % Synoptic Background Profile
    cfg.bg_z0_m double = 0.05 % [m] Surface roughness length for terrain.
    cfg.bg_ustar double = 0.3 % [m/s] Friction velocity representing surface stress.
    cfg.bg_kappa double = 0.4 % [ ] von Kármán constant.
    cfg.bg_blh double = 1.5   % [km] boundary layer height

    % Low-Level Somali Jet - Onshore SW Monsoon flow
    cfg.sj_w double = 12       % [m/s] (zonal) onshore wind speeds of the SW monsoon jet
    cfg.sj_uv double = 14      % [m/s] (meridional) onshore wind speeds of the SW monsoon jet
    cfg.sj_center double = 1.5 % [km] Altitude of the jet core center.
    cfg.sj_s double = 0.8      % [km] Gaussian standard deviation controlling vertical thickness of the jet.

    % Palghat Gap Funneling
    cfg.pg_gamma_funnel double = 0.45; % [ ] 45% wind speed increase from Bernoulli funneling through the mountain pass.
    cfg.pg_pc_elev double = 0.6        % [km] Pass core elevation
    cfg.pg_pc_thick double = 0.5       % [km] Pass core vertical thickness.

    % Tropical Easterly Jet (u_tej, v_tej)
    cfg.tej_u double = 35       % [m/s] (zonal) Strong easterly (westward) jet core speed near the tropopause.
    cfg.tej_v double = 3        % [m/s] (zonal) Strong easterly (westward) jet core speed near the tropopause.
    cfg.tej_alt double = 15.0   % [km] TEJ core altitude
    cfg.tej_vthick double = 2.5 % [km] TEJ core vertical layer thickness.

    % Stratospheric Quasi-Biennial Oscillation
    cfg.qbo_lambda double = 20 % [km] Vertical wavelength of alternating wind regimes in the stratosphere.
    cfg.qbo_u double = 8       % [m/s] Peak zonal amplitude of QBO phase shifts.
    cfg.qbo_v double = 3       % [m/s] Peak meridional amplitude of QBO phase shifts.
    cfg.qbo_alt double = 17    % [km] Altitude of QBO region

    % Orographic Updraft
    cfg.ou_alpha_slope double = atan(1.5 / 30.0); % [ ] Western Ghats ridge terrain slope (1.5 km height rise over 30 km distance).
    cfg.ou_H_lift double = 3.5;                   % [km] Vertical decay scale

    % Continuous Gravity Wave Spectrum
    cfg.gw_nmodes double = 20        % [ ] Number of continuous gravity wave spectrum modes
    cfg.gw_amp double = 2.5          % [m/s] Scaling factor for gravity wave horizontal velocity
	cfg.gw_max_lambda double = 4.0;  % [km] Upper limit for gravity wave vertical scale
	cfg.gw_damp_scale double = 12.0; % [km] Tightened damping scale (was 18.0 km) to control upper amplitude
    cfg.gw_cf double = 0.05          % [ ] Coupling factor deriving vertical wave speed from horizontal wave speed
    cfg.lw_Hs double = 7.0           % [km] Density scale height for wave amplification (e^(z / 2H_s))
    cfg.lw_N_bv double = 0.012;      % [rad/s] Brunt-Väisälä buoyancy frequency

    % Atmospheric Jitter & Thermal Convection
    cfg.jitter_amp double = 0.4    % [m/s] Amplitude of low-frequency spatial jet jitter
    cfg.plume_count double = 4     % [ ] Number of random convective updrafts/downdrafts
    cfg.plume_max_alt double = 6.0 % [km] Maximum altitude ceiling for thermal plumes

    % Kolmogorov Turbulence & Intermittency
    cfg.kt_vaf double = 0.25           % [ ] Vertical anisotropy scaling factor
    cfg.kt_bf double = 1               % [ ] Baseline factor for turbulence scaling
    cfg.kt_maxT double = 2.5           % [ ] Maximum turbulence boost under instability
    cfg.kt_Ric double = 0.25           % [ ] Critical Richardson Number Threshold
    cfg.kt_tlpeak double = 3           % [km] Turbulence layer peak altitude
    cfg.kt_vthick double = 2.5         % [km] Vertical thickness scale of turbulent layer
    cfg.turb_interm_sigma double = 0.5 % [ ] Intermittency parameter for log-normal weighting
end

% Height grid configuration (km)
z = (0:cfg.dz:cfg.max_height)';  % Height vector (0 to 32 km)
z_m = z * 1000;                  % Height in meters
N = length(z);

%% Synoptic Background Profile
% Smooth logarithmic boundary layer fading by 2 km
u_bl = (cfg.bg_ustar / cfg.bg_kappa) * log((z_m + cfg.bg_z0_m) / cfg.bg_z0_m) .* exp(-z / cfg.bg_blh);

%% Low-Level Somali Jet (~1.5 km peak) - Onshore SW Monsoon flow
u_llj = cfg.sj_w * exp(-((z - cfg.sj_center) / cfg.sj_s).^2);
v_llj = cfg.sj_uv * exp(-((z - cfg.sj_center) / cfg.sj_s).^2);

%% Palghat Gap Funneling (low-level acceleration)
u_gap = u_llj .* (1 + cfg.pg_gamma_funnel * exp(-((z - cfg.pg_pc_elev) / cfg.pg_pc_thick).^2));

%% Tropical Easterly Jet (~15 km peak)
u_tej = cfg.tej_u * exp(-((z - cfg.tej_alt) / cfg.tej_vthick).^2);
v_tej = cfg.tej_v * exp(-((z - cfg.tej_alt) / cfg.tej_vthick).^2);

%% Stratospheric QBO Regime (17 - 32 km)
qbo_envelope = 0.5 * (1 + tanh((z - cfg.qbo_alt) / 2.0)); % Smooth step-on instead of hard cut
u_qbo = cfg.qbo_u * sin(2 * pi * (z - cfg.qbo_alt) / cfg.qbo_lambda) .* qbo_envelope;
v_qbo = cfg.qbo_v * cos(2 * pi * (z - cfg.qbo_alt) / cfg.qbo_lambda) .* qbo_envelope;

%% Combine horizontal components with Spatial Jitter
u_mean = u_bl + u_gap + u_tej + u_qbo;
v_mean = v_llj + v_tej + v_qbo;

jitter_u = cfg.jitter_amp * smoothdata(randn(N, 1), 'gaussian', 30);
jitter_v = cfg.jitter_amp * smoothdata(randn(N, 1), 'gaussian', 30);
u_mean = u_mean + jitter_u;
v_mean = v_mean + jitter_v;

%% 2. Orographic Updraft
w_oro = max(0, u_mean) * tan(cfg.ou_alpha_slope) .* exp(-z / cfg.ou_H_lift);

%% 3. Continuous Gravity Wave Spectrum
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

% Damping scale tightened (12 km) to stop growth above tropopause
amp_growth = exp(z / (2 * cfg.lw_Hs)) .* exp(-z / cfg.gw_damp_scale);
u_gw = cfg.gw_amp * (u_wave_spec / std(u_wave_spec)) .* amp_growth;
v_gw = cfg.gw_amp * (v_wave_spec / std(v_wave_spec)) .* amp_growth;
w_gw = -cfg.gw_cf * u_gw;

%% 4. Random Convective Plumes in Lower Troposphere
w_plumes = zeros(N, 1);
for p = 1:cfg.plume_count
    z_center = 0.8 + rand() * (cfg.plume_max_alt - 0.8); % Core altitude
    w_peak = (rand() - 0.3) * 2.5;                      % Peak vertical draft (-0.75 to +1.75 m/s)
    w_width = 0.2 + rand() * 0.4;                       % Plume layer thickness
    w_plumes = w_plumes + w_peak * exp(-((z - z_center)/w_width).^2);
end

%% 5. Stable Kolmogorov Turbulence with Log-Normal Intermittency
% Vertical wind shear (s^-1)
du_dz = gradient(u_mean, cfg.dz * 1000);
dv_dz = gradient(v_mean, cfg.dz * 1000);
shear_sq = du_dz.^2 + dv_dz.^2 + 1e-8; % 1e-8 prevents division by zero

% Gradient Richardson Number (Ri)
Ri = (cfg.lw_N_bv^2) ./ shear_sq;
turb_boost = cfg.kt_bf + cfg.kt_maxT * (Ri < cfg.kt_Ric) .* exp(-((z - cfg.kt_tlpeak)/cfg.kt_vthick).^2);

% Spatial wavenumber vector for 1D Fourier spectral filtering.
k_vec = [(0:floor(N/2)), (-floor((N-1)/2):-1)]' / (N * cfg.dz);

% Fundamental spatial frequency floor preventing low-frequency filter blowup.
k_min = 1 / (N * cfg.dz);
k_abs = max(abs(k_vec), k_min);

% Amplitude shaping filter (k^(-5/6) yields k^(-5/3) power spectrum when squared)
H_turb = k_abs.^(-5/6);
H_turb(1) = 0; % Zero DC term to prevent constant offset blowup

% Generate zero-mean unit-variance noise
raw_u = real(ifft(fft(randn(N, 1)) .* H_turb));
raw_v = real(ifft(fft(randn(N, 1)) .* H_turb));
raw_w = real(ifft(fft(randn(N, 1)) .* H_turb));

% Normalize noise after IFFT
norm_u = (raw_u - mean(raw_u)) / std(raw_u);
norm_v = (raw_v - mean(raw_v)) / std(raw_v);
norm_w = (raw_w - mean(raw_w)) / std(raw_w);

% Log-Normal Intermittency Multiplier (Technique B)
mu_interm = -0.5 * cfg.turb_interm_sigma^2;
interm_weight = exp(mu_interm + cfg.turb_interm_sigma * norm_u);

% Baseline turbulence scaling with background shear & log-normal intermittency
sigma_base = 0.15 + 0.4 * (sqrt(shear_sq) / max(sqrt(shear_sq)));
sigma_turb = sigma_base .* turb_boost .* interm_weight;

u_turb = norm_u .* sigma_turb;
v_turb = norm_v .* sigma_turb;
w_turb = norm_w .* (sigma_turb * cfg.kt_vaf);

%% Final 3D Wind Vector Assembly
u = u_mean + u_gw + u_turb;
v = v_mean + v_gw + v_turb;
w = w_oro + w_gw + w_plumes + w_turb;
end
