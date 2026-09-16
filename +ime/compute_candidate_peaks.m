function candidates = compute_candidate_peaks(spectra, noise_level, vel_axis)
% IME.COMPUTE_CANDIDATE_PEAKS Computes prospective candidate peaks within adaptive Doppler windows.
%
%   Restricts peak search to an adaptive Doppler window (width = 20% total bandwidth) centered
%   around the Doppler velocity traced from the preceding range bin. Extracts up to 3 candidate
%   peaks per bin with SNR > 0 dB, computing power-weighted mean Doppler velocities.

arguments (Input)
	% Denoised power spectra matrix (RangeBins x NFFT).
	spectra (:, 1024) double
	% Noise level vector per range bin.
	noise_level (1, :) double
	% 1 x NFFT Doppler velocity axis vector (m/s).
	vel_axis (1, :) double
end
arguments (Output)
	% 1 x RangeBins cell array of candidate peak structs.
	candidates (1, :) cell
end

[numRangeBins, nfft] = size(spectra);
candidates = cell(1, numRangeBins);

total_bandwidth = max(vel_axis) - min(vel_axis);
half_width = (0.20 * total_bandwidth) / 2;

previous_velocity = NaN;

for r = 1:numRangeBins
	P = spectra(r, :);
	Sn = noise_level(r);

	if r == 1
		[~, peak_idx] = max(P);
		center_velocity = vel_axis(peak_idx);
	else
		center_velocity = previous_velocity;
	end

	lower_velocity = center_velocity - half_width;
	upper_velocity = center_velocity + half_width;

	idx_window = find(vel_axis >= lower_velocity & vel_axis <= upper_velocity);

	if isempty(idx_window)
		candidates{r} = struct([]);
		continue;
	end

	Pworking = P(idx_window);
	selected = struct('idx', {}, 'velocity', {}, 'power', {}, 'snr_db', {}, 'width', {});

	for p = 1:3
		if isempty(Pworking), break; end

		[max_amp, local_idx] = max(Pworking);
		if max_amp <= 0, break; end

		left = local_idx;
		while left > 1 && Pworking(left-1) > 0
			left = left - 1;
		end

		right = local_idx;
		while right < length(Pworking) && Pworking(right+1) > 0
			right = right + 1;
		end

		P_peak = Pworking(left:right);
		V_peak = vel_axis(idx_window(left:right));

		total_peak_power = sum(P_peak);
		if total_peak_power <= 0, break; end
		mean_velocity = sum(P_peak .* V_peak) / total_peak_power;

		if Sn > 0
			total_noise_power = Sn * nfft;
			snr_linear = total_peak_power / total_noise_power;
		else
			snr_linear = Inf;
		end
		snr_db = 10 * log10(snr_linear);

		if snr_db <= 0, break; end

		newCandidate.idx = idx_window(local_idx);
		newCandidate.velocity = mean_velocity;
		newCandidate.power = total_peak_power;
		newCandidate.snr_db = snr_db;
		newCandidate.width = (right - left + 1);

		selected(end+1) = newCandidate;
		Pworking(left:right) = 0;
	end

	candidates{r} = selected;

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
