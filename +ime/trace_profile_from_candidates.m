function profile = trace_profile_from_candidates(candidates, off_zenith, delta_R)
% IME.TRACE_PROFILE_FROM_CANDIDATES Dynamic programming tracer for optimal velocity profile.
%
%   Processes candidate peaks in groups of 5 range bins using dynamic programming to find
%   the optimal continuous Doppler velocity profile. Maximizes the cost function:
%   C = w1 * T(x) + w2 * P_rj, where T(x) is a trapezoidal wind shear continuity membership
%   function (bounded by delta_vm = 0.05 * sin(theta) * delta_R) and P_rj is normalized SNR.

arguments (Input)
	% Cell array of candidate peak structs per range bin.
	candidates (1, :) cell
	% Beam off-zenith angle in degrees.
	off_zenith (1, 1) double
	% Range resolution step in meters (c * BaudLength / 2).
	delta_R (1, 1) double
end
arguments (Output)
	% Array of traced profile structs containing velocity, power, and snr_db per bin.
	profile struct
end

numRangeBins = length(candidates);

profile = struct('velocity', cell(numRangeBins, 1), ...
	'power', cell(numRangeBins, 1), ...
	'snr_db', cell(numRangeBins, 1));

w1 = 0.4;
w2 = 0.6;
group_size = 5;

theta_rad = deg2rad(abs(off_zenith));
delta_vm = 0.05 * sin(theta_rad) * delta_R;
if delta_vm < 0.5
	delta_vm = 0.5;
end

for g = 1:ceil(numRangeBins / group_size)
	start_bin = (g - 1) * group_size + 1;
	end_bin = min(g * group_size, numRangeBins);
	bins_in_group = end_bin - start_bin + 1;

	cost_dp = cell(bins_in_group, 1);
	path_dp = cell(bins_in_group, 1);

	peaks_curr = candidates{start_bin};
	num_peaks = length(peaks_curr);

	if num_peaks == 0
		cost_dp{1} = 0;
		path_dp{1} = {1};
		peaks_curr = struct('velocity', NaN, 'power', NaN, 'snr_db', NaN);
		candidates{start_bin} = peaks_curr;
	else
		snr_max = max([peaks_curr.snr_db]);
		if snr_max <= 0, snr_max = 1; end

		cost_dp{1} = zeros(num_peaks, 1);
		path_dp{1} = num2cell(1:num_peaks)';

		for p = 1:num_peaks
			P_rj = peaks_curr(p).snr_db / snr_max;
			cost_dp{1}(p) = w2 * P_rj;
		end
	end

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

			for p = 1:num_prev
				if isnan(peaks_curr(c).velocity) || isnan(peaks_prev(p).velocity)
					x = inf;
				else
					x = abs(peaks_curr(c).velocity - peaks_prev(p).velocity);
				end

				if x <= delta_vm
					T_x = 1;
				elseif x <= 2 * delta_vm
					T_x = (2 * delta_vm - x) / delta_vm;
				else
					T_x = 0;
				end

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

	[~, best_final_idx] = max(cost_dp{bins_in_group});
	best_path = path_dp{bins_in_group}{best_final_idx};

	for i = 1:bins_in_group
		r = start_bin + i - 1;
		selected_peak_idx = best_path(i);
		chosen_peak = candidates{r}(selected_peak_idx);

		profile(r).velocity = chosen_peak.velocity;
		profile(r).power    = chosen_peak.power;
		profile(r).snr_db   = chosen_peak.snr_db;
	end
end
end
