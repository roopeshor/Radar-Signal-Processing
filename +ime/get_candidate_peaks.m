function candidates = get_candidate_peaks(Pclean, noise_level, vel_axis)
% IME_ADAPTIVE_WINDOWS (Step B)
% Adaptive Doppler-window and prospective peak selection.
    [numRangeBins, nfft] = size(Pclean);
    candidates = cell(numRangeBins, 1);
    % The Doppler window width is limited to 20% of the entire Doppler axis
    total_bandwidth = max(vel_axis) - min(vel_axis);
    half_width = (0.20 * total_bandwidth) / 2;

    previous_velocity = NaN;

    for r = 1:numRangeBins
        P = Pclean(r, :);
        Sn = noise_level(r);

        % 1. Determine Adaptive Window Center
        if r == 1
            [~, peak_idx] = max(P);
            center_velocity = vel_axis(peak_idx);
        else
            center_velocity = previous_velocity;
        end

        % 2. Extract the Search Window
        lower_velocity = center_velocity - half_width;
        upper_velocity = center_velocity + half_width;

        idx_window = find(vel_axis >= lower_velocity & vel_axis <= upper_velocity);

        if isempty(idx_window)
            candidates{r} = struct([]);
            continue;
        end

        Pworking = P(idx_window);
        selected = struct('idx', {}, 'velocity', {}, 'power', {}, 'snr_db', {}, 'width', {});

        % 3. Iteratively select up to 3 prospective peaks
        for p = 1:3
            if isempty(Pworking), break; end

            [max_amp, local_idx] = max(Pworking);
            if max_amp <= 0, break; end % No more valid signals

            % Find boundaries (zero crossings) within the window
            left = local_idx;
            while left > 1 && Pworking(left-1) > 0
                left = left - 1;
            end

            right = local_idx;
            while right < length(Pworking) && Pworking(right+1) > 0
                right = right + 1;
            end

            % Extract the actual peak segment data
            P_peak = Pworking(left:right);
            V_peak = vel_axis(idx_window(left:right));

            % Calculate True Moments
            total_peak_power = sum(P_peak); % 0th Moment (Total Power)
            mean_velocity = sum(P_peak .* V_peak) / total_peak_power; % 1st Moment (Power-weighted velocity)

            % Calculate SNR
            if Sn > 0
                total_noise_power = Sn * nfft;
                snr_linear = total_peak_power / total_noise_power;
            else
                snr_linear = Inf;
            end
            snr_db = 10 * log10(snr_linear);

            % Paper requires SNR > 0 dB to be considered a valid peak
            if snr_db <= 0, break; end

            % Save candidate
            newCandidate.idx = idx_window(local_idx); % Index of absolute maximum
            newCandidate.velocity = mean_velocity;    % Power-weighted velocity (highly precise)
            newCandidate.power = total_peak_power;
            newCandidate.snr_db = snr_db;
            newCandidate.width = (right - left + 1);

            selected(end+1) = newCandidate;

            % Mask out this peak with 0s to search for the next one
            Pworking(left:right) = 0;
        end

        candidates{r} = selected;

        % 4. Determine center for next range bin (Trace closest peak)
        if ~isempty(selected)
            velocities = [selected.velocity];
            [~, closest] = min(abs(velocities - center_velocity));
            previous_velocity = velocities(closest);
        else
            if r == 1
                previous_velocity = center_velocity;
            end
        end
    end
end
