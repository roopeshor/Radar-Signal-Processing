function new_beam = compute_moments(beam, options)
% ST.COMPUTE_MOMENTS Calculates Doppler moments via clutter notch, HS noise floor subtraction, and parabolic fit.
%
%   Applies a clutter notch around the DC bin, estimates noise floor using Hildebrand-Sekhon
%   statistics, subtracts the noise floor, and uses 3-point parabolic peak interpolation to derive
%   sub-bin mean Doppler frequency shift (M1 in Hz). Evaluates total signal power (M0) and spectral
%   width variance (M2).

arguments (Input)
	% Radar beam object containing spectra (or denoised_spectra) and timing parameters.
	beam RadarData
	% Number of bins on each side of DC to zero out for clutter notch.
	options.clutter_notch_bins (1,1) double = 1
end
arguments (Output)
	% Modified RadarData beam populated with M0, M1 (Hz), and M2 profiles.
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

bin_indices = (0:(nfft-1)) - nfft/2;
Ts  = ipp_us * n_coh * 1e-6;
df  = 1 / (Ts * nfft);
freq = bin_indices / (Ts * nfft);

dc_bin = nfft / 2 + 1;

M0 = zeros(1, height_bins);
M1 = zeros(1, height_bins);
M2 = zeros(1, height_bins);

for i = 1:height_bins

	P = P_input(i, :);

	% Apply DC clutter notch
	notch_start = max(1,    dc_bin - options.clutter_notch_bins);
	notch_end   = min(nfft, dc_bin + options.clutter_notch_bins);
	P(notch_start:notch_end) = 0;

	% Hildebrand-Sekhon noise floor estimation
	P_sorted = sort(P);
	noise_level = P_sorted(1);
	for k = length(P_sorted):-1:2
		subset = P_sorted(1:k);
		if var(subset) <= mean(subset)^2
			noise_level = mean(subset);
			break;
		end
	end

	P = P - noise_level;
	P(P < 0) = 0;

	[~, l] = max(P);

	% 3-point parabolic peak interpolation for sub-bin M1 precision
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

	M0(i) = sum(P);
	M2(i) = sum(((freq - M1(i)) .^ 2) .* P) / M0(i);

end

beam.M0 = M0;
beam.M1 = M1;
beam.M2 = M2;
new_beam = beam;
end
