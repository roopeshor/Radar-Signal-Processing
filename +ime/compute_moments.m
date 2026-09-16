function new_beam = compute_moments(beam)
% IME.COMPUTE_MOMENTS Calculates spectral moments for a RadarData beam using IME dynamic programming.

arguments (Input)
	% Radar beam object containing spectra and header parameters.
	beam RadarData
end
arguments (Output)
	% Modified RadarData beam populated with M0, M1 (Hz), M2, SNR, noise_level, and algorithm_parameters.
	new_beam RadarData
end

beam = ime.beam_profile_tracer(beam);

num_bins = beam.m_sNumOfRangeBins;
M0 = zeros(1, num_bins);
M1 = NaN(1, num_bins);
M2 = NaN(1, num_bins);
SNR = -Inf(1, num_bins);

profile = beam.algorithm_parameters.ime_profile;
vel_factor = 299792458 / 205e6 / 2.0;

for r = 1:num_bins
	if ~isempty(profile(r).velocity) && ~isnan(profile(r).velocity)
		M1(r) = -profile(r).velocity / vel_factor;

		if ~isempty(profile(r).power) && ~isnan(profile(r).power)
			M0(r) = profile(r).power;
		end
		if ~isempty(profile(r).snr_db) && ~isnan(profile(r).snr_db)
			SNR(r) = profile(r).snr_db;
		end
	end
end

beam.M0 = M0;
beam.M1 = M1;
beam.M2 = M2;
beam.SNR = SNR;

new_beam = beam;
end
