function new_beam = compute_all_params(beam, cfg)
%   beam - RadarData object with BeamData cube [RangeBins x NFFT x InCoh]
%   prev_frame_peaks - Array of peak indices from the previous frame (optional)

arguments (Input)
	beam RadarData
	cfg.prev_frame_peaks (1,:) double = []
	% whether to apply mclms filter
	cfg.apply_mclms (1,1) logical = true
	% window coefficient
	cfg.win_coeff (1,1) double = 2
	% max wind shear velocity (e.g., 1.0 m/s)
	cfg.wind_shear (1,1) double = 1
	% velocity resolution (e.g., 0.06 m/s)
	cfg.velocity_res (1,1) double = 0.06
	% cost weigths: [velocity continuity weight, peak power weight]
	cfg.cost_weights (1,2) double = [0.5, 0.5]
end
arguments (Output)
	new_beam RadarData
end
beamData = beam.BeamData;
[height_bins, nfft, ~] = size(beamData);

% algorithm parameters

alpha =cfg.win_coeff;
max_shear =cfg.wind_shear;
dv =cfg.velocity_res;

if (isfield(beam.algorithm_parameters, "alpha"))
	alpha = beam.algorithm_parameters.alpha;
end
if (isfield(beam.algorithm_parameters, "max_shear"))
	max_shear = beam.algorithm_parameters.max_shear;
end
if (isfield(beam.algorithm_parameters, "velocity_res"))
	dv = beam.algorithm_parameters.velocity_res;
end
df = round(max_shear / dv); % wind shear bin offset
w1 = cfg.cost_weights(1);
w2 = cfg.cost_weights(2);
mclms_len = 10;                     % mCLMS filter length

M0 = zeros(1, height_bins);
M1 = zeros(1, height_bins);
M2 = zeros(1, height_bins);
cost_scores = zeros(height_bins, nfft);
mclms_denoised_spectra = zeros(height_bins, nfft);
peaks_idx = zeros(height_bins, 1);

F0 = []; % spectral peak of previous range bin[cite: 4]

spectra = fft(beam.BeamData, [], 2);
spectra = mean(spectra, 3);
noise_val = median(abs(spectra), 2);
[height_bins, nfft] = size(spectra);
% Zero-frequency DC clutter mask
mask_bins = [1, 2, 3, nfft, nfft-1];
rand_phase = exp(1j * 2 * pi * rand(height_bins, length(mask_bins)));
spectra(:, mask_bins) = noise_val .* rand_phase;
CS = ifft(spectra / max(spectra(:)), [], 2);


% space time doppler window (inclusive bounds)
% 'height_bins' pairs of (min, max)
ST_W_array = zeros(height_bins, 2);
for r = 1:height_bins
	signal_clean = CS(r, :);
	% -----------------------------------------------------------------
	% setting Space-Time Doppler Window (ST-W)
	% -----------------------------------------------------------------
	if r == 1
		% full spectrum for first bin
		ST_W = 1:nfft;
	else
		% space window
		W1 = max(1, round(F0 - alpha*df)) : min(nfft, round(F0 + alpha*df));
		if ~isempty(cfg.prev_frame_peaks) && length(cfg.prev_frame_peaks) >= r
			T0 = cfg.prev_frame_peaks(r);
			% time window
			W2 = max(1, round(T0 - alpha*df)) : min(nfft, round(T0 + alpha*df));
			inter_W = intersect(W1, W2);
			if length(inter_W) >= alpha * df
				ST_W = inter_W;
			else
				ST_W = W1;
			end
		else
			ST_W = W1;
		end
	end
	ST_W_array(r, :) = [min(ST_W), max(ST_W)];

	% -----------------------------------------------------------------
	% mutual Convolution & Optimal/Suboptimal Vector Selection
	% -----------------------------------------------------------------

	seg_len = floor(nfft / 2);
	num_delays = 8;
	step = floor((nfft - seg_len) / (num_delays - 1));

	v_r1 = signal_clean(1:seg_len);
	V_conv = zeros(num_delays - 1, seg_len);
	max_powers = zeros(1, num_delays - 1);

	for d = 2:num_delays
		start_idx = 1 + (d-1)*step;
		v_ri = signal_clean(start_idx : start_idx + seg_len - 1);
		v_ri_hr = conj(v_ri(end:-1:1));
		v_ci = conv(v_r1, v_ri_hr);

		% get seg_len points from center
		v_ci_center = v_ci(floor(seg_len/2) : floor(3*seg_len/2) - 1);
		V_conv(d-1, :) = v_ci_center;

		spec_d = abs(fftshift(fft(v_ci_center, nfft))).^2;
		% max power inside ST-W
		max_powers(d-1) = max(spec_d(ST_W));
	end

	[~, best_d_idx] = max(max_powers);
	% optimal solution
	X_opt = V_conv(best_d_idx, :);

	% suboptimal solution is adjacent to optimal
	if best_d_idx > 1
		X_sopt = V_conv(best_d_idx - 1, :);
	else
		X_sopt = V_conv(best_d_idx + 1, :);
	end

	% -----------------------------------------------------------------
	% modified Complex LMS (MCLMS) Adaptive Filter
	% -----------------------------------------------------------------
	Y_r = X_opt;
	if (cfg.apply_mclms)
		Y_r = mccf.mclms_filter(X_opt, X_sopt, mclms_len);
	end

	spec_mclms = abs(fftshift(fft(Y_r, nfft))).^2;
	spec_mclms = spec_mclms / max(spec_mclms);
	mclms_denoised_spectra(r, :) = spec_mclms;

	% -----------------------------------------------------------------
	% candidate Peak Selection & Cost Function
	% -----------------------------------------------------------------
	if r == 1
		% initial peak selection
		avg_conv = mean(V_conv, 1);
		final_spectr = abs(fftshift(fft(avg_conv, nfft))).^2;
		[~, selected_peak_idx] = max(final_spectr);
	else
		ST_W_spec = spec_mclms(ST_W);
		M_rmax = max(ST_W_spec);

		[pks, locs_in_stw] = findpeaks(ST_W_spec);
		% peaks that are atleast 40% of max peak
		valid_mask = pks >= 0.4 * M_rmax;
		cand_pks = pks(valid_mask);
		cand_locs = ST_W(locs_in_stw(valid_mask));

		if isempty(cand_locs)
			[~, max_rel_idx] = max(ST_W_spec);
			cand_locs = ST_W(max_rel_idx);
			cand_pks = M_rmax;
		end

		% select top 3 peaks
		[cand_pks, sort_idx] = sort(cand_pks, 'descend');
		if length(cand_locs) > 3
			cand_locs = cand_locs(sort_idx(1:3));
			cand_pks = cand_pks(sort_idx(1:3));
		end

		best_cost = -inf;
		selected_peak_idx = cand_locs(1);

		for c = 1:length(cand_locs)
			cand_idx = cand_locs(c);
			cand_power = cand_pks(c);

			% velocity cost
			V_cost = 1 - abs((cand_idx - F0) * dv) / (alpha * max_shear);

			% cost function
			cost_val = w1 * V_cost + w2 * cand_power;
			cost_scores(r, cand_idx) = cost_val;

			if cost_val > best_cost
				best_cost = cost_val;
				selected_peak_idx = cand_idx;
			end
		end
	end

	F0 = selected_peak_idx;
	peaks_idx(r) = selected_peak_idx;

	% -----------------------------------------------------------------
	% moment Estimation (M0, M1, M2)
	% -----------------------------------------------------------------
	l = selected_peak_idx;
	minI = l; maxI = l;
	while minI > 1 && spec_mclms(minI - 1) > 0
		minI = minI - 1;
	end
	while maxI < nfft && spec_mclms(maxI + 1) > 0
		maxI = maxI + 1;
	end

	signal_block = spec_mclms(minI:maxI);
	indices = (minI:maxI) - 1;

	M0(r) = sum(signal_block);
	freq = (indices - (nfft / 2)) / (beam.ipp_us * beam.n_coh * nfft * 1e-6);
	M1(r) = sum(signal_block .* freq) / M0(r);
	M2(r) = sum(((freq - M1(r)).^2) .* signal_block) / M0(r);
end

beam.M0 = M0;
beam.M1 = M1;
beam.M2 = M2;
beam.denoised_spectra = mclms_denoised_spectra;
beam.algorithm_parameters.mccf_cost_scores = cost_scores;
beam.algorithm_parameters.mccf_ST_W = ST_W_array;
beam.algorithm_parameters.peaks_idx = peaks_idx;
new_beam = beam;
end
