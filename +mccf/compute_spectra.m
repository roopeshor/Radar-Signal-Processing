function spectra = compute_spectra(beam)
% compute_spectra Process the radar beam data to compute power spectra using MCCF method.
%
%   Input Arguments:
%       beam - obtained from read_raw_file
%   Output Arguments:
%       spectra - normalized power spectra of each height (column vector)

arguments (Input)
	beam RadarData
end
arguments (Output)
	spectra (:, 1024) double  % double (RangeBins × NFFT)
end
beamData = beam.BeamData;
[rangeBins, nfft, nInCoh] = size(beamData);
spectraCube = zeros(rangeBins, nfft, nInCoh);

% Define mutual convolution segment size
% We split 1024 points into 4 overlapping segments of 512 points
seg_len = 512;
num_delays = 4;
step = floor((nfft - seg_len) / (num_delays - 1));

for bin = 1:rangeBins
	for inCoh = 1:nInCoh
		signal = squeeze(beamData(bin, :, inCoh));

		% 1. Clutter removal in Frequency Domain
		F_sig = fft(signal);
		% Find noise level (median is a simple baseline)
		noise_val = median(abs(F_sig));
		% Mask DC and adjacent bins to remove clutter (e.g., bin 1, 2, 3 and N, N-1)
		mask_bins = [1, 2, 3, nfft, nfft-1];
		% Replace with noise (with random phase to simulate background noise)
		F_sig(mask_bins) = noise_val * exp(1j * 2 * pi * rand(1, length(mask_bins)));
		% Back to time domain
		signal_clean = ifft(F_sig);

		% 2. Mutual Convolution
		% Extract initial segment V_r1
		v_r1 = signal_clean(1:seg_len);

		% Accumulator for the convolved results
		conv_accum = zeros(1, 2*seg_len - 1);

		for d = 2:num_delays
			start_idx = 1 + (d-1)*step;
			v_ri = signal_clean(start_idx : start_idx+seg_len-1);
			% Hermitian reversal
			v_ri_hr = conj(v_ri(end:-1:1));

			v_ci = conv(v_r1, v_ri_hr);
			conv_accum = conv_accum + v_ci;
		end
		conv_accum = conv_accum / (num_delays - 1);

		% Pad or truncate back to nfft (1024)
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

		% 3. MCLMS Filter (Approximation via smoothing)
		% A true MCLMS minimizes the difference between desired signal and actual output.
		% For this framework, we apply a smoothing filter over the convolved output
		% to emulate the active clutter and noise elimination.
		smoothed_sig = smoothdata(padded_sig, 'gaussian', 5);

		% 4. Final Power Spectrum
		spec = abs(fftshift(fft(smoothed_sig))) .^ 2;
		spectraCube(bin, :, inCoh) = spec;
	end
end

% Incoherent Integration (Average across the InCoh axis - dim 3)
spectraCube = mean(spectraCube, 3);
spectra = squeeze(spectraCube);

% normalize
max_vals = max(spectra, [], 2);
max_vals(max_vals == 0) = 1;
spectra = spectra ./ max_vals;
end
