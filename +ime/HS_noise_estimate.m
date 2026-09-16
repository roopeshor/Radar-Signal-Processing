function noise_level = HS_noise_estimate(spectra, M)
% ime.hs_noise_estimate  Hildebrand-Sekhon noise estimation.

arguments (Input)
	spectra (:, 1024) double
	M (1,1) double = 1 % number of incoherent integrations
end
arguments (Output)
	% [1 x rangeBins] vector of noise levels per range bin
	noise_level (1, :) double
end

[numRangeBins, N] = size(spectra);
noise_level = zeros(1, numRangeBins);

for r = 1:numRangeBins
	A = sort(spectra(r, :), 'ascend');
	n = (1:N);
	Pn = cumsum(A) ./ n;
	secondMoment = cumsum(A.^2) ./ n;
	Qn = secondMoment - Pn.^2;
	Qn(Qn <= 0) = NaN;

	Rn = (Pn.^2) ./ (M .* Qn);
	valid = find(Rn > 1);

	if isempty(valid)
		k = max(1, round(0.1 * N));
	else
		k = max(valid);
	end

	noise_level(r) = Pn(k);
end
end
