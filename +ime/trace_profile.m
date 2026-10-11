function profile = trace_profile(candidates, off_zenith, delta_R)
% Uses dynamic programming to find the optimal continuous velocity profile
% through the candidate peaks by maximizing the IME Cost Function.

    numRangeBins = length(candidates);

    profile = struct('velocity', zeros(1, numRangeBins), ...
                     'power', zeros(1, numRangeBins), ...
                     'snr_db', zeros(1, numRangeBins));

    % Algorithm Parameters from the paper
    w1 = 0.4; % Continuity weight
    w2 = 0.6; % Normalized SNR weight
    group_size = 5;

    % Maximum allowable wind shear (delta_vm)
    % Eq: |delta_vm| <= 0.05 * sin(theta) * delta_R
    % We add a fallback of 0.5 m/s for the vertical beam (where theta=0).
    delta_vm = max(0.5, 0.05 * sind(off_zenith) * delta_R);

    % We process the data in groups of 5 range bins
    for g = 1:ceil(numRangeBins / group_size)
        start_bin = (g - 1) * group_size + 1;
        end_bin = min(g * group_size, numRangeBins);
        bins_in_group = end_bin - start_bin + 1;

        % DP variables for this group
        cost_dp = cell(bins_in_group, 1);
        path_dp = cell(bins_in_group, 1);

        % Initialization for the first bin in the group
        peaks_curr = candidates{start_bin};
        num_peaks = length(peaks_curr);

        if num_peaks == 0
            % Fallback if no peaks found
            cost_dp{1} = 0;
            path_dp{1} = {1};
            peaks_curr = struct('velocity', NaN, 'power', NaN, 'snr_db', NaN);
            candidates{start_bin} = peaks_curr;
        else
            snr_max = max([peaks_curr.snr_db]);
            if snr_max <= 0, snr_max = 1; end % Prevent division by zero

            cost_dp{1} = zeros(num_peaks, 1);
            path_dp{1} = num2cell(1:num_peaks)';

            for p = 1:num_peaks
                % Normalized SNR P_rj
                P_rj = peaks_curr(p).snr_db / snr_max;
                % Initial cost is just the SNR weight (no wind shear yet)
                cost_dp{1}(p) = w2 * P_rj;
            end
        end

        % Process the rest of the bins in the group
        for i = 2:bins_in_group
            r = start_bin + i - 1;
            peaks_prev = candidates{r-1};
            peaks_curr = candidates{r};

            if isempty(peaks_curr)
                peaks_curr = struct('velocity', NaN, 'power', NaN, 'snr_db', NaN);
                candidates{r} = peaks_curr;
            end

            num_prev = length(peaks_prev);
            num_curr = length(peaks_curr);

            snr_max = max([peaks_curr.snr_db]);
            if snr_max <= 0, snr_max = 1; end

            new_cost_dp = zeros(num_curr, 1);
            new_path_dp = cell(num_curr, 1);

            for c = 1:num_curr
                max_path_cost = -inf;
                best_prev_idx = 1;

                P_rj = peaks_curr(c).snr_db / snr_max;

                % Check transition from all previous peaks
                for p = 1:num_prev
                    % wind shear
                    if isnan(peaks_curr(c).velocity) || isnan(peaks_prev(p).velocity)
                        x = inf; % Break continuity if NaN
                    else
                        x = abs(peaks_curr(c).velocity - peaks_prev(p).velocity);
                    end

                    % Trapezoidal membership function T(x)
                    if x <= delta_vm
                        T_x = 1;
                    elseif x <= 2 * delta_vm
                        T_x = (2 * delta_vm - x) / delta_vm;
                    else
                        T_x = 0;
                    end

                    % Cost function evaluation
                    transition_cost = w1 * T_x + w2 * P_rj;
                    total_cost = cost_dp{i-1}(p) + transition_cost;

                    if total_cost > max_path_cost
                        max_path_cost = total_cost;
                        best_prev_idx = p;
                    end
                end

                new_cost_dp(c) = max_path_cost;
                new_path_dp{c} = [path_dp{i-1}{best_prev_idx}, c];
            end
            cost_dp{i} = new_cost_dp;
            path_dp{i} = new_path_dp;
        end

        % Backtracking: Find the highest accumulated cost trace at the end of the group
        [~, best_final_idx] = max(cost_dp{bins_in_group});
        best_path = path_dp{bins_in_group}{best_final_idx};

        % Save the chosen peaks to the final profile
        for i = 1:bins_in_group
            r = start_bin + i - 1;
            selected_peak_idx = best_path(i);
            chosen_peak = candidates{r}(selected_peak_idx);

            profile.velocity(r) = chosen_peak.velocity;
            profile.power(r)    = chosen_peak.power;
            profile.snr_db(r)   = chosen_peak.snr_db;
        end
    end
end
