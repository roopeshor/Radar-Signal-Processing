function spectra = compute_spectra(beam)
% SIMPLE.COMPUTE_SPECTRA Computes baseline Doppler power spectra using mean DC subtraction and FFT.
%
%   Performs time-domain DC component subtraction across NFFT samples, evaluates 1D Fast Fourier
%   Transforms along the pulse time series, applies zero-frequency fftshift, computes magnitude-squared
%   spectral power, and averages power incoherently across integrations.

arguments (Input)
	% Radar beam object containing raw IQ complex time-series cube (BeamData).
	beam RadarData
end
arguments (Output)
	% RangeBins x NFFT matrix of normalized power spectra.
	spectra (:, 1024) double
end

% DC Removal in time domain
beamData = beam.BeamData - mean(beam.BeamData, 2);

% Doppler FFT across pulse time series
spectraCube = fft(beamData, [], 2);
spectraCube = abs(fftshift(spectraCube, 2)) .^ 2;

% Incoherent integration and global peak normalization
spectraCube = mean(spectraCube, 3);
spectra = squeeze(spectraCube);
spectra = spectra / max(spectra(:));
end
