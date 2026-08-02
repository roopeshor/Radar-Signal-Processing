function spectra = compute_spectra_from_beam_data(beamData, window)
	arguments
		beamData (:, 1024, 1) double  % double complex (RangeBins × NFFT × InCohIntegrations)
		window function_handle = @hann
	end

	% compute_spectra_from_beam_data Process the radar beam data to compute power spectra.
	%
	%   Input Arguments:
	%       beamData - obtained from read_raw_file, dimension:(RangeBins, NFFT, InCohIntegrations)
	%       window - window function used (default: hann)
	%   Output Arguments:
	%       denoised_spectra - noise subtracted normalized power spectra of each height (column vector)
	%       spectra - normalized power spectra of each height (column vector)
	%       noise_level - noise level computed using hildebrand sekhon method (column vector)

	[~, nfft, ~] = size(beamData);

	% DC Removal (Subtract the mean along the NFFT time axis - which is dim 2)
	beamData = beamData - mean(beamData, 2);

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
