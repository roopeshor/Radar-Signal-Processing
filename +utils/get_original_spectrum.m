function spectra = get_original_spectrum(beam)
	% Computes normalized spectrum from given beam with no further processing
	% doesnt do any squaring
arguments (Input)
	% Radar beam object containing raw IQ complex time-series cube (BeamData).
	beam RadarData
end
arguments (Output)
	spectra (:, 1024) double
end
spectraCube = fft(beam.BeamData, [], 2);
spectraCube = fftshift(spectraCube, 2);

% Incoherent integration and normalization
% taking mean right now works because there is onty 1 incoherent integration
spectraCube = mean(spectraCube, 3);
spectra = squeeze(spectraCube);
spectra = spectra / max(spectra(:));
end
