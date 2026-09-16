function new_beam = compute_moments(beam)
% MCCF.COMPUTE_MOMENTS Computes Doppler spectral moments using cost-function-guided peak tracking.
%
%   Identifies surviving spectral peaks across range bins and selects the atmospheric peak by
%   minimizing a composite cost penalty balancing spectral amplitude against vertical Doppler shift
%   discontinuity: Penalty = W_power * (1 / Power) + W_jump * (|loc - prev_loc| / NFFT). Integration
%   is bounded by local zero-crossings to evaluate total power (M0), mean Doppler shift in Hz (M1),
%   and spectral width variance (M2).

arguments (Input)
	beam RadarData
end
arguments (Output)
	new_beam RadarData
end

ipp_us = beam.ipp_us;
n_coh = beam.n_coh;

if ~isempty(beam.denoised_spectra)
	P_filtered = beam.denoised_spectra;
else
	P_filtered = beam.spectra;
	warning("No denoised spectra found in beam")
end

[height_bins, nfft] = size(P_filtered);

M0 = zeros(1, height_bins);
M1 = zeros(1, height_bins);
M2 = zeros(1, height_bins);

prev_peak_idx = round(nfft / 2);
cost_scores = zeros(height_bins, nfft);

W_power = 0.8;
W_jump = 0.2;

for i = 1:height_bins
	P = P_filtered(i, :);

	[pks, locs] = findpeaks(P);

	if isempty(pks)
		[~, l] = max(P);
		locs = l;
		pks = P(l);
	end

	best_penalty = inf;
	best_loc = locs(1);

	for p_idx = 1:length(locs)
		loc = locs(p_idx);
		power = pks(p_idx);

		power_penalty = 1 / (power + 1e-6);

		if i == 1
			jump_penalty = 0;
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
	prev_peak_idx = l;

	% Bounding spectral peak to zero-crossings
	minI = l;
	maxI = l;
	while minI > 1 && P(minI - 1) > 0
		minI = minI - 1;
	end

	while maxI < nfft && P(maxI + 1) > 0
		maxI = maxI + 1;
	end

	signal_block = P(minI:maxI);
	indices = (minI:maxI) - 1;

	M0(i) = sum(signal_block);
	freq = (indices - (nfft / 2)) / (ipp_us * n_coh * nfft * 1e-6);
	M1(i) = sum(signal_block .* freq) / M0(i);
	M2(i) = sum(((freq - M1(i)) .^ 2) .* signal_block) / M0(i);
end

beam.M0 = M0;
beam.M1 = M1;
beam.M2 = M2;
beam.algorithm_parameters.mccf_cost_scores = cost_scores;
new_beam = beam;
end
