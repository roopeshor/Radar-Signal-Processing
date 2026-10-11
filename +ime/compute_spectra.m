function spectra = compute_spectra(beam)
% Takes raw complex IQ data and generates the averaged Doppler power spectrum.
arguments (Input)
	beam RadarData
end
arguments (Output)
	spectra (:, 1024) double
end
raw_iq = beam.BeamData;
[~, nfft, num_incoh] = size(raw_iq);
win = reshape(hanning(nfft), 1, nfft, 1);
windowed_iq = raw_iq .* win;
S = fftshift(fft(windowed_iq, [], 2), 2);
spectra = mean(abs(S).^2, 3) / num_incoh;
end
