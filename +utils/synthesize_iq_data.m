function BeamData = synthesize_iq_data(cfg)
% UTILS.SYNTHESIZE_IQ_DATA Synthesizes complex IQ time-series data using Zrnic spectral simulation.
%
%   Generates Gaussian power spectrum signatures modeled on Doppler velocity, spectral width, and SNR,
%   applies complex Gaussian noise shaping (Zrnic method), and computes inverse FFT to yield IQ time series.

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
	% width of DC component across range bins.
	cfg.sigma_dc (1, :) double = []
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
	cfg.sigma_dc = (randn(1, nRangeBins)  + 4) / 12;
end
f = linspace(-PRF_eff/2, PRF_eff/2 - PRF_eff/NFFT, NFFT);
BeamData = zeros(nRangeBins, NFFT, 1);

bright_band_ranges = cfg.bright_bands(:, 1);
i = 1;
for z = 1:nRangeBins
	P_sig = P_noise * cfg.SNR(z);
	S_sig = exp(-(f - fd(z)).^2 / (2 * sigma_f(z)^2));

	if sum(S_sig) > 0
		S_sig = S_sig / sum(S_sig) * P_sig / (sqrt(2 * pi) * sigma_f(z));
	else
		S_sig = zeros(1, NFFT);
	end

	% add Noise
	S_noise = (P_noise / NFFT) * ones(1, NFFT);
	S = S_sig + S_noise;

	% add DC
	S_dc = (cfg.dc_rel_power * (exp(z / nRangeBins) - .7)) * sum(S) * exp(-f.^2 / (2 * cfg.sigma_dc(z)^2));
	S = S + S_dc;

	if (i <= length(bright_band_ranges) && bright_band_ranges(i) == z)
		% add bright band (adding after DC, because im anticipating some dc explosion)
		% 30-40dB range
		S_bb = sum(S) * 10 ^ (-40/10) * (rand()/3 + 1) * exp(-f.^2 / (2 * cfg.bright_bands(i, 2)^2));
		S = S + S_bb;
		i = i+1;
	end


	if cfg.add_iq_noise
		X = randn(1, NFFT);
		Y = randn(1, NFFT);
		Z = sqrt(S/2) .* (X + 1i * Y);
	else
		Z = sqrt(S/2);
	end

	% Inverse FFT from centered Doppler spectrum Z to time series s
	s = ifft(ifftshift(Z)) * sqrt(NFFT);
	BeamData(z, :, 1) = s;
end
BeamData = round(BeamData);
end
