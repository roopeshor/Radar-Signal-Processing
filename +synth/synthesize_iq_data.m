function BeamData = synthesize_iq_data_vectrzd(cfg)
% Synthesizes complex IQ time-series data using Zrnic spectral simulation.
%
%   Generates Gaussian power spectrum signatures modeled on Doppler velocity, spectral width, and SNR,
%   applies complex Gaussian noise shaping (Zrnic method), and computes inverse FFT to yield IQ time series.
% Vectorized function
arguments (Input)
	% Radial velocity profile vector (m/s).
	cfg.vr (1, :) double
	% BeamHeader object containing NFFT, RangeBins, IPP, and coherent integration parameters.
	cfg.Header BeamHeader
	% Spectral width (m/s).
	cfg.spec_w (1, :) double
	% Signal-to-noise ratio array across range bins.
	cfg.SNR (1, :) double = []
	% Flag to enable complex IQ Gaussian noise synthesis.
	cfg.add_iq_noise logical = true
	% additional dc offset. this fraction of peak value of spectrum is added to signal in time domain
	cfg.dc_rel_power double = 0
	% ground clutter power. this fraction of peak value of spectrum is added to signal in time domain
	cfg.gc_rel_power double = 0.005
	% width of DC component across range bins.
	cfg.sigma_dc (1, :) double = []
	% width of ground clutter across range bins.
	cfg.sigma_gc (1, :) double = []
	% list of height bin and bright band widths
	cfg.bright_bands (:, 2) double = []
end
arguments (Output)
	% Synthesized complex IQ time-series data cube (RangeBins x NFFT x InCoh).
	BeamData (:, :, :) double
end

NFFT = cfg.Header.m_sNFFT;
nRangeBins = cfg.Header.m_sNumOfRangeBins;
ipp_us = cfg.Header.m_fIntrPulsePeriod_us;
cohIn = cfg.Header.m_sNumOfCohIntegrations;

P_noise = 1000;
wavelen  = 3e8 / 205e6;
DBS_V = wavelen/2;
fd      = -cfg.vr / DBS_V;
PRF_eff = 1 / (ipp_us * 1e-6 * cohIn);
sigma_f = 2 * cfg.spec_w / wavelen;
if isempty(cfg.SNR)
	cfg.SNR = 10 .^ (linspace(40, -40, nRangeBins)' / 10);
end

if isempty(cfg.sigma_dc)
	cfg.sigma_dc = ones(1, nRangeBins) / 20;
end
if isempty(cfg.sigma_gc)
	cfg.sigma_gc = 1./((1:nRangeBins) / 10) / 5;
end

f = linspace(-PRF_eff/2, PRF_eff/2 - PRF_eff/NFFT, NFFT);
bright_band_ranges = round(cfg.bright_bands(:, 1));

% column orientation for range-bin parameters
fd_col       = fd(:);
sigma_f_col  = sigma_f(:);
SNR_col      = cfg.SNR(:);
sigma_dc_col = cfg.sigma_dc(:);
sigma_gc_col = cfg.sigma_gc(:);
f_row        = reshape(f, 1, NFFT);

P_sig     = P_noise * SNR_col;
S_sig     = exp(-(f_row - fd_col).^2 ./ (2 * sigma_f_col.^2));
sum_S_sig = sum(S_sig, 2);

scale = zeros(nRangeBins, 1);
valid = sum_S_sig > 0;
scale(valid) = (P_sig(valid) ./ sum_S_sig(valid)) ./ (sqrt(2 * pi) * sigma_f_col(valid));
S_sig = S_sig .* scale;

S = S_sig + (P_noise / NFFT);

% DC Component
sum_S = sum(S, 2);
S = S + (cfg.dc_rel_power * sum_S) .* exp(-f_row.^2 ./ (2 * sigma_dc_col.^2));

% Ground Clutter
sum_S = sum(S, 2);
S = S + (cfg.gc_rel_power * sum_S) .* exp(-f_row.^2 ./ (2 * sigma_gc_col.^2));

% Bright Bands
num_bb = size(cfg.bright_bands, 1);
for k = 1:num_bb
	z_idx = bright_band_ranges(k);
	if z_idx >= 1 && z_idx <= nRangeBins
		ampl = sum(S(z_idx, :)) * 10 ^ rescale(k, -3.5, 2, 'InputMin', 1, 'InputMax', nRangeBins);
		S(z_idx, :) = S(z_idx, :) + ampl * exp(-f_row.^2 / (2 * cfg.bright_bands(k, 2)^2));
	end
end

S_sqrt = sqrt(S / 2);
if cfg.add_iq_noise
	X = randn(nRangeBins, NFFT);
	Y = randn(nRangeBins, NFFT);
	Z = S_sqrt .* (X + 1i * Y);
else
	Z = S_sqrt;
end

BeamData = round(ifft(ifftshift(Z, 2), [], 2) * sqrt(NFFT));

end
