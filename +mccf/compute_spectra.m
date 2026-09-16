function spectra = compute_spectra(beam)
% MCCF.COMPUTE_SPECTRA Computes power spectra using Mutual Cross-Correlation Function (MCCF).
%
%   Processes complex IQ time series by applying frequency-domain DC clutter masking,
%   segmenting the signal into overlapping windows, and computing cross-correlations
%   (mutual convolution with Hermitian reversal) across delayed segments to suppress
%   uncorrelated noise. A Gaussian smoothing filter is applied before FFT shift and
%   incoherent integration.

arguments (Input)
	% Radar beam object containing raw IQ complex time-series cube (BeamData).
	beam RadarData
end
arguments (Output)
	% RangeBins x NFFT matrix of normalized power spectra.
	spectra (:, 1024) double
end

beamData = beam.BeamData;
[rangeBins, nfft, nInCoh] = size(beamData);
spectraCube = zeros(rangeBins, nfft, nInCoh);

seg_len = 512;
num_delays = 4;
step = floor((nfft - seg_len) / (num_delays - 1));

for bin = 1:rangeBins
	for inCoh = 1:nInCoh
		signal = squeeze(beamData(bin, :, inCoh));

		% Frequency-domain ground clutter masking around DC bins
		F_sig = fft(signal);
		noise_val = median(abs(F_sig));
		% Mask DC and adjacent bins to remove clutter (e.g., bin 1, 2, 3 and N, N-1)
		mask_bins = [1, 2, 3, nfft, nfft-1];
		% Replace with noise (with random phase to simulate background noise)
		F_sig(mask_bins) = noise_val * exp(1j * 2 * pi * rand(1, length(mask_bins)));
		signal_clean = ifft(F_sig);

		% Mutual convolution across delayed segments with Hermitian reversal
		v_r1 = signal_clean(1:seg_len);

		% Accumulator for the convolved results
		conv_accum = zeros(1, 2*seg_len - 1);

		for d = 2:num_delays
			start_idx = 1 + (d-1)*step;
			v_ri = signal_clean(start_idx : start_idx+seg_len-1);
			v_ri_hr = conj(v_ri(end:-1:1));

			v_ci = conv(v_r1, v_ri_hr);
			conv_accum = conv_accum + v_ci;
		end
		conv_accum = conv_accum / (num_delays - 1);

		% Center-truncate or zero-pad accumulated correlation to NFFT length
		final_len = length(conv_accum);
		if final_len < nfft
			padded_sig = zeros(1, nfft);
			offset = floor((nfft - final_len)/2);
			padded_sig(offset+1 : offset+final_len) = conv_accum;
		elseif final_len > nfft
			offset = floor((final_len - nfft)/2);
			padded_sig = conv_accum(offset+1 : offset+nfft);
		else
			padded_sig = conv_accum;
		end

		% Gaussian adaptive noise filtering prior to Doppler FFT
		smoothed_sig = smoothdata(padded_sig, 'gaussian', 5);

		spec = abs(fftshift(fft(smoothed_sig))) .^ 2;
		spectraCube(bin, :, inCoh) = spec;
	end
end

% Incoherent integration and peak normalization
spectraCube = mean(spectraCube, 3);
spectra = squeeze(spectraCube);

max_vals = max(spectra, [], 2);
max_vals(max_vals == 0) = 1;
spectra = spectra ./ max_vals;
end
