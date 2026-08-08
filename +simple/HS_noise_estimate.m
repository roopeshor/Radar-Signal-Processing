function noise_level = HS_noise_estimate(spectrums, M)
	% HS_noise_estimate  Estimate the mean noise floor of a
	%   Doppler power spectrum using the Hildebrand-Sekhon method.
	%
	%   noise_level = HS_noise_estimate(spectrums, M)
	%
	%   The algorithm assumes that the noise component of the spectrum obeys
	%   a chi-squared distribution.  It sorts each row of the spectrum in
	%   ascending order and computes a running mean P_n and running variance
	%   Q_n.  The statistic R_n = P_n^2 / (Q_n * M) approaches 1 for pure
	%   noise samples.  The algorithm scans from the high end of the sorted
	%   sequence and locates the last index where R_n exceeds 1; the mean
	%   P_n at that index is taken as the noisspectrumse floor for that range bin.
	%
	%   Algorithm steps
	%   ---------------
	%     1. Sort each row of 'spectrums' in ascending order -> A
	%     2. Compute running statistics along the sorted axis:
	%            P_n  = cumsum(A)  ./ n          (running mean)
	%            Q_n  = cumsum(A²) ./ n - P_n²   (running variance)
	%     3. Form the H-S discriminant:
	%            R_n  = P_n² / (Q_n * M)
	%        R_n > 1 indicates the truncated subset still contains signal;
	%        R_n ≈ 1 indicates the subset is noise-only.
	%     4. For each range bin, find the highest-index sorted sample for
	%        which R_n > 1 and return the corresponding P_n as the noise
	%        floor estimate.
	%
	%   Input Arguments
	%   ---------------
	%     spectrums - Normalised power spectrum matrix.
	%                 Each row is the Doppler spectrum for one range bin, as
	%                 returned by compute_simple_spectra before noise subtraction.
	%     M         - Number of incoherent integrations used
	%                 when acquiring the spectra.  Scales Q_n to account for
	%                 the reduced variance after averaging.
	%
	%   Output Arguments
	%   ----------------
	%     noise_level - double (height_bins x 1).  Estimated mean noise power per
	%                   Doppler bin for each range bin.
	%
	%   See also compute_simple_spectra, compute_moments

	arguments
		spectrums (:, 1024) double
		M (1,1) double
	end

	[height_bins, N] = size(spectrums);

	% Step 1: Reorder the spectrum in ascending order along axis 2
	A = sort(spectrums, 2);

	n_arr = (0:(N-1)) + N;
	nm = repmat(n_arr, height_bins, 1);

	% Step 2: Compute P_n (running mean) and Q_n (running variance)
	P_n = cumsum(A, 2) ./ nm;
	n_arr = 1:N;
	nm = repmat(n_arr, height_bins, 1);
	Q_n = (cumsum(A.^2, 2) ./ nm) - (P_n.^2);

	% Compute R_n
	R_n = (P_n.^2) ./ (Q_n * M);

	% Step 3: Find the cutoff index
	noise_level = zeros(height_bins, 1);

	for i = 1:height_bins
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
