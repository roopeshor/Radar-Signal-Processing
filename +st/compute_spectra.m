function spectra = compute_spectra(beam)
% ST.COMPUTE_SPECTRA Computes power spectra using pre-FFT coherent time-domain accumulation.
%
%   Applies a Hanning window to IQ complex time series, coherently sums complex IQ signals across
%   all incoherent integrations in the time domain before FFT, and computes fftshift magnitude-squared
%   power spectra. Coherent time-domain summing preserves phase coherence, matching reference pipeline SNR.

arguments (Input)
	% Radar beam object containing raw IQ complex time-series cube (BeamData).
	beam RadarData
end
arguments (Output)
	% RangeBins x NFFT matrix of linear-scale power spectra.
	spectra (:, 1024) double
end

[~, nfft, ~] = size(beam.BeamData);

win = reshape(hann(nfft), [1, nfft, 1]);
beamWindowed = beam.BeamData .* win;

% Coherent sum across integrations prior to FFT for phase preservation
beamCohSum = sum(beamWindowed, 3);
spectraCube = fft(beamCohSum, [], 2);

spectra = abs(fftshift(spectraCube, 2)) .^ 2;
end
