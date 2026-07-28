function noise_level = estimate_noise_hildebrand_sekhon(spectrums, M)
    % estimate_noise_hildebrand_sekhon Estimates the noise level threshold.
    
    [bins, N] = size(spectrums);
    
    % Step 1: Reorder the spectrum in ascending order along axis 2
    A = sort(spectrums, 2);
    
    n_arr = 1:N;
    nm = repmat(n_arr, bins, 1);
    
    % Step 2: Compute P_n (running mean) and Q_n (running variance)
    P_n = cumsum(A, 2) ./ nm;
    Q_n = (cumsum(A.^2, 2) ./ nm) - (P_n.^2);
    
    % Compute R_n
    warning('off', 'MATLAB:divideByZero');
    R_n = (P_n.^2) ./ (Q_n * M);
    warning('on', 'MATLAB:divideByZero');
    
    % Step 3: Find the cutoff index
    noise_level = zeros(bins, 1);
    
    for i = 1:bins
        arr = fliplr(R_n(i, :));
        
        idx_0based = 0; % Default if not found (Python argmax default for no True)
        for j = 1:length(arr)
            if ~isnan(arr(j)) && arr(j) > 1.0
                idx_0based = j - 1;
                break;
            end
        end
        
        valid_idx_0based = N - 1 - idx_0based;
        % +1 for MATLAB 1-based indexing
        noise_level(i) = P_n(i, valid_idx_0based + 1);
    end
end
