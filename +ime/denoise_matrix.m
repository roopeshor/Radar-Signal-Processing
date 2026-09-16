function [clean_spectra, noise_level] = denoise_matrix(spectra, M)
%ime.denoise_matrix denoises given spectra with HS noise subtraction and 5-point moving mean.
% also returns computed noise_level
arguments (Input)
	spectra (:, 1024) double
	M (1,1) double % number of incoherent integrations
end
arguments (Output)
	clean_spectra (:, 1024) double
	noise_level (1, :) double
end
clean_spectra = movmean(spectra, 5, 2);

noise_level = ime.HS_noise_estimate(clean_spectra, M);

[num_bins, ~] = size(clean_spectra);
for r = 1:num_bins
	clean_spectra(r, :) = clean_spectra(r, :) - noise_level(r);
end
clean_spectra(clean_spectra < 0) = 0;
end
