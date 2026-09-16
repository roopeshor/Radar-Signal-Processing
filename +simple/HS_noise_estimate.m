function noise_level = HS_noise_estimate(beam)
% SIMPLE.HS_NOISE_ESTIMATE Estimates mean noise floor using Hildebrand-Sekhon chi-squared statistics.
%
%   Sorts spectral bins in ascending order for each range bin and computes running mean P_n and
%   running variance Q_n. Scans the test statistic R_n = P_n^2 / (M * Q_n) to isolate the maximum
%   noise-only subset (R_n > 1) and returns the corresponding mean noise floor.

arguments (Input)
	% Radar beam object containing spectra and incoherent integration parameters.
	beam RadarData
end
arguments (Output)
	% Estimated mean noise level vector (1 x RangeBins).
	noise_level (1, :) double
end

M = beam.m_sNumOfInCohIntegrations;
[height_bins, N] = size(beam.spectra);

A = sort(beam.spectra, 2);

n_arr = (0:(N-1)) + N;
nm = repmat(n_arr, height_bins, 1);

P_n = cumsum(A, 2) ./ nm;
n_arr = 1:N;
nm = repmat(n_arr, height_bins, 1);
Q_n = (cumsum(A.^2, 2) ./ nm) - (P_n.^2);

R_n = (P_n.^2) ./ (Q_n * M);

noise_level = zeros(height_bins, 1);

for i = 1:height_bins
	arr = fliplr(R_n(i, :));

	idx_0based = 0;
	for j = 1:length(arr)
		if ~isnan(arr(j)) && arr(j) > 1.0
			idx_0based = j - 1;
			break;
		end
	end

	valid_idx_0based = N - 1 - idx_0based;
	noise_level(i) = P_n(i, valid_idx_0based + 1);
end
end
