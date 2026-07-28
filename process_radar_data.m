function [denoised_spectra, spectra, noise_level] = process_radar_data(raw_data_matrix)
    % process_radar_data Process the radar raw data to generate power spectra and noise level.
    %
    %   Input Arguments:
    %       raw_data_matrix - obtained from Read_data, dimension:(RangeBins, NFFT, InCohIntegrations)
    %   Output Arguments:
    %       denoised_spectra - noise subtracted normalized power spectra of each height (column vector)
    %       spectra - normalized power spectra of each height (column vector)
    %       noise_level - noise level computed using hildebrand sekhon method (column vector)
    
    [~, nfft, incoh] = size(raw_data_matrix);
    
    % DC Removal (Subtract the mean along the NFFT time axis - which is dim 2)
    dc_mean = mean(raw_data_matrix, 2);
    dc_removed = raw_data_matrix - dc_mean;
    
    % Windowing with hann
    n = 0:(nfft-1);
    window = 0.5 * (1 - cos(2 * pi * n / (nfft - 1)));
    
    % Reshape window to match (1, NFFT, 1) for broadcasting
    % ie, repeats it along height direction
    window_reshaped = reshape(window, [1, nfft, 1]);
    windowed_data = dc_removed .* window_reshaped;
    
    % FFT (Shift zero-frequency to the center of the array)
    % FFT along dimension 2
    spectra = fft(windowed_data, [], 2);
    spectra = fftshift(spectra, 2);
    
    % Calculate Power Spectrum (Magnitude squared and normalized)
    denoised_spectra = abs(spectra).^2;
    denoised_spectra = denoised_spectra / max(denoised_spectra(:));
    
    % Incoherent Integration (Average across the InCoh axis - dim 3)
    spectra = mean(denoised_spectra, 3);
    
    % Squeeze to remove InCoh axis
    spectra = squeeze(spectra);
    
    % normalize
    spectra = spectra / max(spectra(:));
    
    % Noise estimation
    noise_level = estimate_noise_hildebrand_sekhon(spectra, incoh);

    % subtract noise level
    noiseLevelPerBin = repmat(noise_level, 1, nfft);
    denoised_spectra = spectra - noiseLevelPerBin;
    
    % zero the negative
    denoised_spectra(denoised_spectra < 0) = 0;
end
