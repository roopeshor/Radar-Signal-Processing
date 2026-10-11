function beam = estimate_params(beam, cfg)
arguments (Input)
	beam RadarData
	cfg.vel_axis (1, :) double
end
arguments (Output)
	beam RadarData
end
candidates = ime.get_candidate_peaks(beam.denoised_spectra, beam.noise_level, cfg.vel_axis);
delta_R = 3.0e8 * beam.m_fBaudLength_us * 1e-6 / 2;
profile = ime.trace_profile(candidates, beam.m_fOffZenith, delta_R);

beam.M1 = profile.velocity;

beam.a_params.ime_candidates = candidates;
beam.a_params.ime_radial_vel = profile.velocity;
beam.a_params.ime_power = profile.power;
beam.a_params.ime_snr_db = profile.snr_db;
end

