function moments = ime_calculate_moments(P, vel_axis, noise_level)
% Calculates true Doppler spectral moments for a given peak.

    % Noise subtraction and bounding
    Ps = P - noise_level;
    Ps(Ps < 0) = 0;

    % Find the peak
    [max_pow, peak_idx] = max(Ps);
    if max_pow <= 0
        moments.M0 = 0; moments.M1 = NaN; moments.M2 = NaN;
        moments.width = NaN; moments.SNR = -Inf;
        return;
    end

    % Trace boundaries of zero-crossings
    left = peak_idx;
    while left > 1 && Ps(left-1) > 0
        left = left - 1;
    end

    right = peak_idx;
    while right < length(Ps) && Ps(right+1) > 0
        right = right + 1;
    end

    % Extract the continuous signal segment
    idx = left:right;
    Pseg = Ps(idx);
    Vseg = vel_axis(idx);

    M0 = sum(Pseg);
    if M0 <= 0
        moments.M0 = 0; moments.M1 = NaN; moments.M2 = NaN;
        moments.width = NaN; moments.SNR = -Inf;
        return;
    end

    M1 = sum(Vseg .* Pseg) / M0;

    M2 = sum(((Vseg - M1).^2) .* Pseg) / M0;
    width = sqrt(M2);

    total_noise = noise_level * length(Ps); % Total noise across the whole NFFT
    SNR = 10 * log10(M0 / total_noise);

    moments.M0 = M0;
    moments.M1 = M1;
    moments.M2 = M2;
    moments.width = width;
    moments.SNR = SNR;
end
