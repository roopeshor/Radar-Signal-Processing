function [M0, M1, M2] = compute_moments(spectrum, ipp_us, n_coh)
	% compute_moments computes woodman moments
	%
	%   Input Arguments:
	%     spectrum - spectrum to process
	%     ipp_us - Inter-Pulse Period in microseconds
	%              The time interval between consecutive transmitted radar pulses.
	%     n_coh - Number of coherent integrations
	%
	%   Output Arguments:
	%     M0 - 0th moment array (column vector)
	%     M1 - 1st moment array (column vector)
	%     M2 - 2nd moment array (column vector)

	arguments
		spectrum (:, 1024) double
		ipp_us (1,1) double
		n_coh (1,1) double
	end
	[height_bins, nfft] = size(spectrum);

	P_filtered = spectrum;

	M0 = zeros(1, height_bins);
	M1 = zeros(1, height_bins);
	M2 = zeros(1, height_bins);
	for i = 1:height_bins
		P = P_filtered(i, :);
		[~, l] = max(P); % l - index of largest element

		% % iteratively find bounds of "valid" values
		minI = l; % index before which values falls to negative
		maxI = l; % index above which values falls to negative
		while minI > 1 && P(minI - 1) > 0
			minI = minI - 1;
		end

		while maxI < nfft && P(maxI + 1) > 0
			maxI = maxI + 1;
		end

		% % extract that piece only
		signal_block = P(minI:maxI);
		indices = minI:maxI;

		% sum along rows (nfft axis)
		M0(i) = sum(signal_block);

		% Map to 0-based index for math
		indices = indices - 1;

		% frequency bins corresponding to each indices
		freq = (indices - (nfft / 2)) / (ipp_us * n_coh * nfft * 1e-6);

		% frequency bin repeated along height direction
		M1(i) = sum(signal_block .* freq) / M0(i);

		M2(i) = sum(((freq - M1(i)) .^ 2) .* signal_block) / M0(i);
	end
end
