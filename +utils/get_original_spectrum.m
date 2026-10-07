function spectra = get_original_spectrum(beam)
arguments (Input)
	% Radar beam object containing raw IQ complex time-series cube (BeamData).
	beam RadarData
end
arguments (Output)
	% RangeBins x NFFT matrix of normalized power spectra.
	spectra (:, 1024) double
end
spectraCube = fft(beam.BeamData, [], 2);
spectraCube = abs(fftshift(spectraCube, 2)) .^ 2;

% Incoherent integration and normalization
spectraCube = mean(spectraCube, 3);
spectra = squeeze(spectraCube);
spectra = spectra / max(spectra(:));
end
