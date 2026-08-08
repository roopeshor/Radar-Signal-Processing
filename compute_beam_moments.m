function out_beam = compute_beam_moments(beam)
	% compute_beam_moments computes woodman moments and stores
	% it in the beam's M0, M1, M2 fields nd returns the modifed beam
	%
	%   Input Arguments:
	%     beam - Number of coherent integrations
	%
	%   Output Arguments:
	%     out_beam - modified beam

	arguments
		beam RadarData
	end
	ipp_us = beam.ipp_us;
	n_coh = beam.n_coh;
	[height_bins, nfft] = size(beam.spectra);

	if ~isempty(beam.denoised_spectra)
		P_filtered = beam.denoised_spectra;
	else
		P_filtered = beam.spectra;
	end

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
	beam.M0 = M0;
	beam.M1 = M1;
	beam.M2 = M2;
	out_beam = beam;
end
