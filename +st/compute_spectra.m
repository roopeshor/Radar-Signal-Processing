function spectra = compute_spectra(beam)
%ST.COMPUTE_SPECTRA  Computes power spectra using the reference pipeline.
%
%   The pipeline matches the algorithm inferred from the reference .mmts files:
%
%     1. Apply Hanning window along the time (NFFT) axis.
%     2. Coherently sum across all InCoh integrations (IQ summing in time domain).
%     3. FFT along the time axis.
%     4. fftshift + magnitude squared → power spectrum.
%
%   This ordering preserves inter-integration phase coherence, yielding the
%   correct SNR (vs. the naive FFT-then-average approach which discards it).
%
%   Input Arguments:
%     beam - RadarData object (BeamData must be populated)
%
%   Output Arguments:
%     spectra - (RangeBins × NFFT) double, linear-scale power spectra

arguments (Input)
	beam RadarData
end
arguments (Output)
	spectra (:, 1024) double  % (RangeBins × NFFT)
end

[~, nfft, ~] = size(beam.BeamData);

% Step 1: Hanning window along time (NFFT) axis - dim 2
%         Reshape to (1, NFFT, 1) for broadcasting across RangeBins and InCoh
win = reshape(hann(nfft), [1, nfft, 1]);
beamWindowed = beam.BeamData .* win;

% Step 2: Coherently sum across InCoh integrations (dim 3)
%         This is key: summing IQ preserves phase coherence, giving
%         SNR gain of nIncoh vs. averaging power spectra which does not.
beamCohSum = sum(beamWindowed, 3);  % (RangeBins × NFFT)

% Step 3: FFT along time axis (dim 2)
spectraCube = fft(beamCohSum, [], 2);

% Step 4: fftshift + magnitude squared → power spectrum
spectra = abs(fftshift(spectraCube, 2)) .^ 2;

end
