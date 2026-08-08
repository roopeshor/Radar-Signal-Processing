function denoised_spectra = denoise_beam(beam)
%denoise_beam denoises beam using hildebrand sekhon method.
% alternatively, modify line 9 to implement own noise estimator
% This function should return modified beam and output should be
% written in denoised_spectra property of beam
arguments (Input)
	beam RadarData
end
arguments (Output)
	denoised_spectra (:, 1024) double  % (RangeBins × NFFT)
end

[~, nfft] = size(beam.spectra);
noise_level = simple.HS_noise_estimate(beam);

% subtract noise level
noiseLevelPerBin = repmat(noise_level, 1, nfft);
denoised_spectra = beam.spectra - noiseLevelPerBin;

% zero the negative
denoised_spectra(denoised_spectra < 0) = 0;
end
