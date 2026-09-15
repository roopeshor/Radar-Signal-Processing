function BeamData = synthesize_iq_data(cfg)
arguments
	% radial velocity
	cfg.vr (1, :) double
	% header data to get some info
	cfg.Header BeamHeader
	% array of snrs
	cfg.SNR (1, :) double = []
	% spectral width
	cfg.spec_w (1, 1) double = 0.3
	% whether to add I/Q noise
	cfg.add_iq_noise logical = true
end

NFFT = cfg.Header.m_sNFFT;
nRangeBins = cfg.Header.m_sNumOfRangeBins;
ipp_us = cfg.Header.m_fIntrPulsePeriod_us;
cohIn = cfg.Header.m_sNumOfCohIntegrations;

P_noise = 1000;    % Noise power in digital units (variance)
wavelen  = 3e8 / 205e6;
DBS_V = wavelen/2;
fd      = -cfg.vr / DBS_V;
PRF_eff = 1 / (ipp_us * 1e-6 * cohIn);
sigma_f = 2 * cfg.spec_w / wavelen;

if isempty(cfg.SNR)
	cfg.SNR = 10 .^ (linspace(40, -40, nRangeBins)' / 10);
end

f = linspace(-PRF_eff/2, PRF_eff/2 - PRF_eff/NFFT, NFFT);
BeamData = zeros(nRangeBins, NFFT, 1);

for z = 1:nRangeBins
	P_sig = P_noise * cfg.SNR(z);
	S_sig = exp(-(f - fd(z)).^2 / (2 * sigma_f^2));

	if sum(S_sig) > 0
		S_sig = S_sig / sum(S_sig) * P_sig / (sqrt(2 * pi) * sigma_f);
	else
		S_sig = zeros(1, NFFT);
	end

	S_noise = (P_noise / NFFT) * ones(1, NFFT);
	S = S_sig + S_noise;

	if cfg.add_iq_noise
		% Zrnic method
		X = randn(1, NFFT);
		Y = randn(1, NFFT);
		Z = sqrt(S/2) .* (X + 1i * Y);
	else
		Z = sqrt(S/2);
	end

	% to Time series
	s = conj(ifft(ifftshift(Z)) * sqrt(NFFT));
	BeamData(z, :, 1) = s;
end
% Convert to int32 range
BeamData = round(BeamData);
end
