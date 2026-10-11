function spectra = compute_spectra_vec(beam, cfg)
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

	% which axis to take maximum
	cfg.max_axis = 2
end
arguments (Output)
	% RangeBins x NFFT matrix of normalized power spectra.
	spectra (:, 1024) double
end

beamData = beam.BeamData;
[rangeBins, nfft, nInCoh] = size(beamData);
% Total number of signals across all range bins and incoherent integrations
M = rangeBins * nInCoh;
seg_len = 512;
num_delays = 4;
step = floor((nfft - seg_len) / (num_delays - 1));

% Reshape beamData to (M x nfft) where each row is one time-series signal
signals = reshape(permute(beamData, [1, 3, 2]), M, nfft);

% Ground Clutter Masking around DC bins
F_sig = fft(signals, [], 2);
noise_val = median(abs(F_sig), 2);
mask_bins = [1, 2, 3, nfft, nfft-1];
rand_phase = exp(1j * 2 * pi * rand(M, length(mask_bins)));
F_sig(:, mask_bins) = noise_val .* rand_phase;
signal_clean = ifft(F_sig, [], 2);

% Mutual Convolution via Frequency-Domain Accumulation
L_conv = 2 * seg_len - 1;
v_r1 = signal_clean(:, 1:seg_len);
V_r1_f = fft(v_r1, L_conv, 2);

% Accumulate FFT of delayed Hermitian-reversed segments across delays
V_ri_sum_f = zeros(M, L_conv);
for d = 2:num_delays
	start_idx = 1 + (d - 1) * step;
	v_ri = signal_clean(:, start_idx : start_idx + seg_len - 1);
	v_ri_hr = conj(fliplr(v_ri));
	V_ri_sum_f = V_ri_sum_f + fft(v_ri_hr, L_conv, 2);
end

% Single inverse FFT to get the accumulated mutual convolution
conv_accum = ifft(V_r1_f .* V_ri_sum_f, [], 2) / (num_delays - 1);

% Center-Truncation / Zero-Padding to NFFT length
if L_conv < nfft
	offset = floor((nfft - L_conv) / 2);
	padded_sig = zeros(M, nfft);
	padded_sig(:, offset+1 : offset+L_conv) = conv_accum;
elseif L_conv > nfft
	offset = floor((L_conv - nfft) / 2);
	padded_sig = conv_accum(:, offset+1 : offset+nfft);
else
	padded_sig = conv_accum;
end

smoothed_sig = smoothdata(padded_sig, 2, 'gaussian', 5);
spec_all = abs(fftshift(fft(smoothed_sig, [], 2), 2)) .^ 2;

% Reshape back to (rangeBins x nInCoh x nfft) and average over nInCoh (dimension 2)
spec_3d = reshape(spec_all, rangeBins, nInCoh, nfft);
spectra = squeeze(mean(spec_3d, 2));

max_vals = max(spectra, [], cfg.max_axis);
max_vals(max_vals == 0) = 1;
spectra = spectra ./ max_vals;
end
