function BeamData = synthesize_iq_data(vr, H)
arguments
	% radial velocity
	vr (1, :) double

	% header data to get some info
	H BeamHeader
end

NFFT = H.m_sNFFT;
nRangeBins = H.m_sNumOfRangeBins;
lambda  = 299792458.0 / 205e6;
P_noise = 1000;    % Noise power in digital units (variance)
fd      = -2 * vr / lambda;
PRF_eff = 1 / (H.m_fIntrPulsePeriod_us * 1e-6 * H.m_sNumOfCohIntegrations);
sigma_v = .3;  % 1 m/s spectral width
sigma_f = 2 * sigma_v / lambda;

f = linspace(-PRF_eff/2, PRF_eff/2 - PRF_eff/NFFT, NFFT);
SNR = 10 .^ (linspace(40, -40, nRangeBins)' / 10);
BeamData = zeros(nRangeBins, NFFT, 1);

for z = 1:nRangeBins
	P_sig = P_noise * SNR(z);
	S_sig = exp(-(f - fd(z)).^2 / (2 * sigma_f^2));

	if sum(S_sig) > 0
		S_sig = S_sig / sum(S_sig) * P_sig / (sqrt(2 * pi) * sigma_f);
	else
		S_sig = zeros(1, NFFT);
	end

	S_noise = (P_noise / NFFT) * ones(1, NFFT);
	S = S_sig + S_noise;

	% Zrnic method
	X = randn(1, NFFT);
	Y = randn(1, NFFT);
	Z = sqrt(S/2) .* (X + 1i * Y);

	% to Time series
	s = conj(ifft(ifftshift(Z)) * sqrt(NFFT));
	BeamData(z, :, 1) = s;
end
% Convert to int32 range
BeamData = round(BeamData);
end
