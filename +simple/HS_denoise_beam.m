function [denoised_spectra, noise_level] = HS_denoise_beam(beam)
% SIMPLE.HS_DENOISE_BEAM Denoises a single RadarData beam by subtracting Hildebrand-Sekhon noise.
%
%   Retrieves or estimates the Hildebrand-Sekhon noise level for each range bin, subtracts the
%   estimated noise floor from the Doppler power spectrum, and zeroes negative spectral intensities.

arguments (Input)
	% Radar beam object containing spectra and incoherent integration parameters.
	beam RadarData
end
arguments (Output)
	% RangeBins x NFFT matrix of noise-subtracted power spectra.
	denoised_spectra (:, 1024) double
	% Estimated noise level per range bin.
	noise_level (1, :) double
end

spec = beam.denoised_spectra;
if (isempty(spec))
	spec = beam.spectra;
end
[~, nfft] = size(spec);
noise_level = beam.noise_level;
if isempty(noise_level)
	noise_level = simple.HS_noise_estimate(beam);
end

noiseLevelPerBin = repmat(noise_level', 1, nfft);
denoised_spectra = spec - noiseLevelPerBin;
denoised_spectra(denoised_spectra < 0) = 0;
end
