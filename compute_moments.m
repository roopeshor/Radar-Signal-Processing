function [M0, M1, M2] = compute_moments(denoised_spectrum, ipp_us, n_coh)
    % compute_moments compute_woodman_moments.
    %   Detailed explanation of the function's behavior can span
    %   across multiple lines here.
    %
    %   Input Arguments:
    %     denoised_spectrum - denoised spectrum
    %     ipp_us - Inter-Pulse Period in microseconds
    %              The time interval between consecutive transmitted radar pulses.
    %     n_coh - Number of coherent integrations
    %
    %   Output Arguments:
    %     M0 - 0th moment array (column vector)
    %     M1 - 1st moment array (column vector)
    %     M2 - 2nd moment array (column vector)
    %

    [heightBins, nfft] = size(denoised_spectrum);

    P_filtered = denoised_spectrum;

    % P_flat_py = reshape( ...
    %     P_filtered.', ... % transpose to get row major order, ie rows are joined together
    %     [], ... % auto calculate the final size
    %     1 ... % only 1 row
    % );

    % [pmax, l] = max(P_flat_py); % l - index of largest elelemt

    % if pmax == 0
    %     M0 = 0.0;
    %     M1 = 0.0;
    %     return;
    % end


    % % % iteratively find bounds of "valid" values
    % minI = l; % index before which values falls to negative
    % maxI = l; % index above which values falls to negative
    % while minI > 1 && P_flat_py(minI - 1) > 0
    %     minI = minI - 1;
    % end

    % while maxI < length(P_flat_py) && P_flat_py(maxI + 1) > 0
    %     maxI = maxI + 1;
    % end

    % % extract that piece only
    % signal_block = P_flat_py(minI:maxI);
    % indices = minI:maxI;
    signal_block = P_filtered;
    indices = 0:(nfft-1);

    % sum along rows (nfft axis)
    M0 = sum(signal_block, 2);

    % Map to 0-based index for math
    indices = indices - 1;

    % effective sampling time
    T_eff = (ipp_us * 1e-6) * n_coh;

    % frequency spacing
    F_D = 1 / (T_eff * heightBins);

    % frequency bins corresponding to each indices
    freq_b = (indices - (heightBins / 2)) * F_D;

    % frequency bin repeated along height direction
    freq = repmat(freq_b, heightBins, 1);

    M1 = sum(signal_block .* freq, 2) ./ M0;

    % M1 repeated along nfft direction
    M1_map = repmat(M1, 1, nfft);
    M2 = sum(((freq - M1_map) .^ 2) .* signal_block, 2) ./ M0;
end
