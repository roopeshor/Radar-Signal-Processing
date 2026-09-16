function spectra = compute_spectra(beam)
% ime.compute_spectra  Computes normalized power spectra for a RadarData beam.
%
%   spectra = ime.compute_spectra(beam)
%
arguments (Input)
	beam RadarData
end
arguments (Output)
	spectra (:, 1024) double
end

raw_iq = beam.BeamData;
[num_bins, nfft, num_incoh] = size(raw_iq);

spectra_raw = zeros(num_bins, nfft);
win = hanning(nfft);

for r = 1:num_bins
	for i = 1:num_incoh
		iq = squeeze(raw_iq(r, :, i));
		windowed_iq = iq(:) .* win;
		S = fftshift(fft(windowed_iq));
		power_S = abs(S).^2;
		spectra_raw(r, :) = spectra_raw(r, :) + power_S';
	end
end

spectra = spectra_raw / num_incoh;
end
