function beam = compute_beam_spectra(beam)
% Computes Doppler power spectra using mean DC subtraction and FFT.

arguments (Input)
	beam RadarData
end
arguments (Output)
	beam RadarData
end

% DC Removal in time domain
beamData = beam.BeamData - mean(beam.BeamData, 2);

% Doppler FFT across pulse time series
spectraCube = fft(beamData, [], 2);
spectraCube = abs(fftshift(spectraCube, 2)) .^ 2;

% Incoherent integration and global peak normalization
spectraCube = mean(spectraCube, 3);
spectra = squeeze(spectraCube);
beam.denoised_spectra = spectra / max(spectra(:));
end
