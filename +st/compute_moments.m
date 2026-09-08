function new_beam = compute_moments(beam, options)
%ST.COMPUTE_MOMENTS  Computes radar moments matching the reference algorithm.
%
%   The algorithm inferred from the reference .mmts files:
%
%     1. Clutter notch: zero out DC bins (±clutter_notch_bins around centre).
%     2. Hildebrand-Sekhon noise estimation on the notched spectrum.
%     3. Subtract noise floor; clip negatives to zero.
%     4. Find the peak bin.
%     5. 3-point parabolic interpolation for sub-bin M1 precision.
%     6. Compute M0, M2 from the denoised spectrum.
%
%   This differs from simple.compute_moments which uses a peak-expand centroid
%   and has no clutter notch, causing it to lock onto DC clutter instead of
%   the atmospheric signal in clutter-contaminated range bins.
%
%   Input Arguments:
%     beam                    - RadarData object. Uses denoised_spectra if
%                               available, otherwise falls back to spectra.
%     options.clutter_notch_bins (1,1) double = 1
%                             - Number of bins on each side of DC to zero out.
%                               Set to 0 to disable the notch.
%
%   Output Arguments:
%     new_beam - RadarData with M0, M1, M2 populated.

arguments (Input)
	beam RadarData
	options.clutter_notch_bins (1,1) double = 1
end
arguments (Output)
	new_beam RadarData
end

ipp_us = beam.ipp_us;
n_coh  = beam.n_coh;

if ~isempty(beam.denoised_spectra)
	P_input = beam.denoised_spectra;
else
	P_input = beam.spectra;
end

[height_bins, nfft] = size(P_input);

% Frequency axis (Hz) corresponding to each FFT bin after fftshift.
% Bins are indexed 0-based as: (k - nfft/2) / (Ts * nfft)
bin_indices = (0:(nfft-1)) - nfft/2;
Ts  = ipp_us * n_coh * 1e-6;       % effective sampling period (s)
df  = 1 / (Ts * nfft);             % frequency resolution (Hz)
freq = bin_indices / (Ts * nfft);  % (1 × NFFT) Hz axis

dc_bin = nfft / 2 + 1;  % 1-based index of the DC (0 Hz) bin after fftshift

M0 = zeros(1, height_bins);
M1 = zeros(1, height_bins);
M2 = zeros(1, height_bins);

for i = 1:height_bins

	P = P_input(i, :);

	% Step 1: Clutter notch — zero out DC and its neighbours.
	%         This prevents DC ground clutter from dominating the peak search.
	notch_start = max(1,    dc_bin - options.clutter_notch_bins);
	notch_end   = min(nfft, dc_bin + options.clutter_notch_bins);
	P(notch_start:notch_end) = 0;

	% Step 2: Hildebrand-Sekhon noise estimation.
	%         Sort spectrum ascending and find the largest subset whose
	%         variance ≤ mean² (i.e., consistent with white noise).
	P_sorted = sort(P);
	noise_level = P_sorted(1);
	for k = length(P_sorted):-1:2
		subset = P_sorted(1:k);
		if var(subset) <= mean(subset)^2
			noise_level = mean(subset);
			break;
		end
	end

	% Step 3: Subtract noise floor, clip to zero.
	P = P - noise_level;
	P(P < 0) = 0;

	% Step 4: Find peak bin.
	[~, l] = max(P);

	% Step 5: 3-point parabolic peak interpolation.
	%         Fits a parabola through P[l-1], P[l], P[l+1] and returns the
	%         analytical peak location for sub-bin frequency precision.
	%         Falls back to the bin centre if at an edge or flat peak.
	if l > 1 && l < nfft
		P_lo   = P(l - 1);
		P_peak = P(l);
		P_hi   = P(l + 1);
		denom  = P_lo - 2*P_peak + P_hi;
		if denom ~= 0
			M1(i) = freq(l) + 0.5 * df * (P_lo - P_hi) / denom;
		else
			M1(i) = freq(l);
		end
	else
		M1(i) = freq(l);
	end

	% Step 6: M0 and M2 from the full denoised spectrum (after notch).
	M0(i) = sum(P);
	M2(i) = sum(((freq - M1(i)) .^ 2) .* P) / M0(i);

end

beam.M0 = M0;
beam.M1 = M1;
beam.M2 = M2;
new_beam = beam;
end
