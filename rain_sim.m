function plot_doppler_spectrogram()
    % ---------------------------------------------------------------------
    % 1. Radar & Simulation Setup
    % ---------------------------------------------------------------------
    radar.Pt = 250e3;            % Peak power [W]
    radar.G = 10^(45/10);        % Gain [linear]
    radar.lambda = 0.10;         % Wavelength [m] (S-band)
    radar.tau = 1e-6;            % Pulse width [s]
    radar.theta_bw = deg2rad(1); % 3-dB beamwidth [rad]
    radar.K2 = 0.93;             % Water dielectric factor
    radar.PRF = 2000;            % PRF [Hz]
    radar.N_pulses = 256;        % FFT size / pulses per gate
    radar.noise_power = 1e-13;   % Noise floor [W]

    el_deg = 90;                 % Vertically pointing radar (90 deg)
    az_deg = 0;                  % Azimuth angle [deg]

    % Height grid: 0 km to 20 km with 100 m resolution
    h_km = (0.1:0.1:20)';         % Height vector [km]
    N_heights = length(h_km);

    % ---------------------------------------------------------------------
    % 2. Height-Dependent Profiles (Rain Rate & Wind Shear)
    % ---------------------------------------------------------------------
    % Rain rate profile: 15 mm/hr at surface, decaying up to echo top at 12 km
    R_rain_profile = 15.0 * exp(-h_km / 5.0);
    R_rain_profile(h_km > 12) = 0; % No scatterers above 12 km

    % Wind profile: u (zonal), v (meridional), w (vertical air motion)
    u_wind = 10 + 2.0 * h_km;        % Horizontal shear [m/s]
    v_wind = -5 + 0.5 * h_km;
    w_wind = 0.2 * sin(2*pi*h_km/4);  % Downdrafts/updrafts [m/s]

    % ---------------------------------------------------------------------
    % 3. Preallocate Spectrogram Matrix & Setup Velocity Axis
    % ---------------------------------------------------------------------
    M = radar.N_pulses;
    f_axis = linspace(-radar.PRF/2, radar.PRF/2 - radar.PRF/M, M)';
    v_axis = -f_axis * radar.lambda / 2; % Velocity axis [m/s]

    spectrogram_data = zeros(N_heights, M); % 2D Matrix [Heights x Velocity]

    % ---------------------------------------------------------------------
    % 4. Compute Power Spectrum at Each Height Gate
    % ---------------------------------------------------------------------
    c = 299792458;
    dr = (c * radar.tau) / 2;
    az = deg2rad(az_deg); el = deg2rad(el_deg);
    r_hat = [cos(el)*sin(az), cos(el)*cos(az), sin(el)];

    for k = 1:N_heights
        R_rain = R_rain_profile(k);
        h_m = h_km(k) * 1000;

        if R_rain <= 0.01
            % Noise-only gate
            S_f = (radar.noise_power / radar.PRF) * ones(M, 1);
        else
            % A. DSD and Weighted Fall Speed (Marshall-Palmer)
            N0 = 8000;
            Lambda = 4.1 * (R_rain^(-0.21));
            D = linspace(0.1, 8.0, 300);
            dD = D(2) - D(1);
            ND = N0 * exp(-Lambda * D);

            Z_linear = sum(ND .* (D.^6) * dD);
            VT = 9.65 - 10.3 * exp(-0.6 * D);
            VT(VT < 0) = 0;

            v_fall = sum(VT .* ND .* (D.^6) * dD) / Z_linear;
            sigma_fall2 = sum(((VT - v_fall).^2) .* ND .* (D.^6) * dD) / Z_linear;

            % B. Received Echo Power (Pr)
            V_vol = (pi / (72 * log(2))) * (h_m * radar.theta_bw)^2 * dr;
            eta = (pi^5 / (radar.lambda^4)) * radar.K2 * (Z_linear * 1e-18);
            Pr = (radar.Pt * radar.G^2 * radar.lambda^2 * eta * V_vol) / ((4*pi)^3 * h_m^4);

            % C. Radial Velocity Projection & Broadening
            wind_vec = [u_wind(k), v_wind(k), w_wind(k)];
            v_total = wind_vec + [0, 0, -v_fall];
            v_r = dot(v_total, r_hat);

            V_cross = norm(wind_vec(1:2));
            sigma_beam2 = (radar.theta_bw / (2*sqrt(2*log(2))) * V_cross)^2;
            sigma_turb2 = 0.5;
            sigma_v = sqrt(sigma_fall2 + sigma_beam2 + sigma_turb2);

            % D. Theoretical Power Spectral Density + Noise Floor
            f_d = -2 * v_r / radar.lambda;
            sigma_f = 2 * sigma_v / radar.lambda;
            N0_density = radar.noise_power / radar.PRF;

            S_f_theoretical = (Pr / (sigma_f * sqrt(2*pi))) * exp(-((f_axis - f_d).^2) / (2 * sigma_f^2)) + N0_density;

            % E. Realize Spectral Fading (Zrnić Method)
            df = radar.PRF / M;
            A = sqrt(S_f_theoretical * df / 2) .* (randn(M, 1) + 1i * randn(M, 1));
            iq_sig = ifft(ifftshift(A)) * M;
            S_f = (abs(fftshift(fft(iq_sig))).^2) / (M * radar.PRF);
        end

        spectrogram_data(k, :) = S_f';
    end

    % ---------------------------------------------------------------------
    % 5. Plot Altitude-Doppler Spectrogram
    % ---------------------------------------------------------------------
    spectrogram_dBm = 10 * log10(spectrogram_data / 1e-3);

    imagesc(v_axis, h_km, spectrogram_dBm);
    axis xy; % Correct vertical direction for height
    colormap(jet);
    c = colorbar;
    c.Label.String = 'Power Spectral Density [dBm/Hz]';
    clim([-140, -40]); % Dynamic range adjustment

    xlabel('Radial Velocity [m/s] (+ Away, - Towards)');
    ylabel('Height [km]');
    title('Doppler Spectrogram of Rain Echo (0 to 20 km)');
    grid on;
end

plot_doppler_spectrogram()
