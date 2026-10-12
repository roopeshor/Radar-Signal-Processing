function beam = denoise_beam(beam)
arguments (Input)
	beam RadarData
end
arguments (Output)
	beam RadarData
end
% 1. Removes ground clutter (DC bin) by interpolation
% 2. Applies a 5-point moving average filter
% 3. Estimates and subtracts Hildebrand-Sekhon noise

if isempty(beam.denoised_spectra)
	Praw = beam.spectra;
else
	Praw = beam.denoised_spectra;
end
[num_bins, nfft] = size(Praw);

dc_idx = floor(nfft / 2) + 1;

% 1. Ground Clutter Removal
% Interpolate the DC bin and its immediate neighbors
% using the average of the points just outside the clutter
left_val = Praw(:, dc_idx - 2);
right_val = Praw(:, dc_idx + 2);
avg_val = (left_val + right_val) / 2;
Praw(:, (dc_idx-1):(dc_idx+1)) = ones(num_bins, 3) .* avg_val;

% 5-point moving average to filter transient interference
Praw = movmean(Praw, 5, 2);

% Noise Estimation using HS
M = beam.m_sNumOfInCohIntegrations;
noise_level = ime.HS_noise_estimate(Praw, M);
Pclean = Praw - noise_level';
Pclean(Pclean < 0) = 0;

beam.denoised_spectra = Pclean;
beam.noise_level = noise_level;
end
