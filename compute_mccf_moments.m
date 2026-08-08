function [M0, M1, M2, alg_params] = compute_mccf_moments(beam)
	% compute_mccf_moments computes woodman moments using MCCF cost function.
	% Stores results in M0, M1, M2 and algorithm parameters.
	% Uses beam.denoised_spectra if available, else beam.spectra.

	arguments
		beam RadarData
	end
	ipp_us = beam.ipp_us;
	n_coh = beam.n_coh;
	[height_bins, nfft] = size(beam.denoised_spectra);

	% Prefer denoised spectra to accurately find bounds of the peak
	% if ~isempty(beam.denoised_spectra)
	% 	P_filtered = beam.denoised_spectra;
	% else
		P_filtered = beam.denoised_spectra;
	% end

	M0 = zeros(1, height_bins);
	M1 = zeros(1, height_bins);
	M2 = zeros(1, height_bins);

	% Space-Time Doppler Window: track previous peak to enforce continuity
	prev_peak_idx = round(nfft / 2);

	cost_scores = zeros(height_bins, nfft);

	for i = 1:height_bins
		P = P_filtered(i, :);

		% Find local maxima (surviving peaks)
		[pks, locs] = findpeaks(P);

		if isempty(pks)
			% fallback if no clear peaks found
			[~, l] = max(P);
			locs = l;
			pks = P(l);
		end

		% Cost function evaluation
		% Penalty = W1 * (1 / Power) + W2 * (Velocity Jump)
		% Adapted weights for 205 MHz ST Radar (decreased velocity jump penalty for wind shear)
		W_power = 1.0;
		W_jump = 0.2;

		best_penalty = inf;
		best_loc = locs(1);

		for p_idx = 1:length(locs)
			loc = locs(p_idx);
			power = pks(p_idx);

			% Normalized power penalty
			power_penalty = 1 / (power + 1e-6);

			% Jump penalty (difference in bins from previous altitude)
			if i == 1
				jump_penalty = 0; % No previous height to compare
			else
				jump_penalty = abs(loc - prev_peak_idx) / nfft;
			end

			penalty = W_power * power_penalty + W_jump * jump_penalty;
			cost_scores(i, loc) = penalty;

			if penalty < best_penalty
				best_penalty = penalty;
				best_loc = loc;
			end
		end

		l = best_loc;
		prev_peak_idx = l; % update for next height bin

		% iteratively find bounds of "valid" values around chosen peak 'l'
		minI = l;
		maxI = l;
		while minI > 1 && P(minI - 1) > 0
			minI = minI - 1;
		end

		while maxI < nfft && P(maxI + 1) > 0
			maxI = maxI + 1;
		end

		% extract that piece only
		signal_block = P(minI:maxI);
		indices = minI:maxI;

		% sum along rows (nfft axis)
		M0(i) = sum(signal_block);

		% Map to 0-based index for math
		indices = indices - 1;

		% frequency bins corresponding to each indices
		freq = (indices - (nfft / 2)) / (ipp_us * n_coh * nfft * 1e-6);

		% M1
		M1(i) = sum(signal_block .* freq) / M0(i);

		% M2
		M2(i) = sum(((freq - M1(i)) .^ 2) .* signal_block) / M0(i);
	end

	% Store algorithm parameters
	alg_params = struct();
	alg_params.cost_scores = cost_scores;
end
