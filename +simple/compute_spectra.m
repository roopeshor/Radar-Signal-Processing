function spectra = compute_spectra(beam)

arguments (Input)
	beam RadarData
end
arguments (Output)
	spectra (:, 1024) double  % (RangeBins × NFFT)
end

% compute_spectra Most simplest spectra computer.
%
%   Input Arguments:
%       beam - obtained from read_raw_file
%       options.window - window function used (default: hann)
%   Output Arguments:
%       spectra - normalized power spectra of each height (column vector)

% [~, nfft, ~] = size(beam.BeamData);

% DC Removal (Subtract the mean along the NFFT time axis - which is dim 2)
beamData = beam.BeamData - mean(beam.BeamData, 2);

% Reshape window to match (1, NFFT, 1) for broadcasting
% ie, repeats it along height direction
% window_reshaped = reshape(window(nfft), [1, nfft, 1]);
% beamData = beamData .* window_reshaped;

% FFT along dimension 2
spectraCube = fft(beamData, [], 2);

% Calculate Power Spectrum (Magnitude squared)
spectraCube = abs(fftshift(spectraCube, 2)) .^ 2;

% Incoherent Integration (Average across the InCoh axis - dim 3)
spectraCube = mean(spectraCube, 3);

% Squeeze to remove InCoh axis, and make spectra a 2D array
spectra = squeeze(spectraCube);

% normalize
spectra = spectra / max(spectra(:));
end
