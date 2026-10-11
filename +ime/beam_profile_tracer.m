function new_beam = beam_profile_tracer(beam)
% IME.BEAM_PROFILE_TRACER Dynamic programming tracer for optimal velocity profile of a RadarData beam.

arguments (Input)
	% Radar beam object containing candidates or raw/denoised spectra.
	beam RadarData
end
arguments (Output)
	% Modified RadarData beam populated with a_params.profile, velocity, power, snr_db.
	new_beam RadarData
end

if (isempty(beam.a_params) ...
	 || ~isfield(beam.a_params, 'ime_candidate_peaks') ...
	 || isempty(beam.a_params.ime_candidate_peaks))
	beam = ime.compute_candidate_peaks_beam(beam);
end
candidates = beam.a_params.ime_candidate_peaks;
off_zenith = beam.m_fOffZenith;
delta_R = 299792458 * beam.m_fBaudLength_us * 1e-6 / 2;

profile = ime.trace_profile_from_candidates(candidates, off_zenith, delta_R);

beam.a_params.ime_profile = profile;
num_bins = length(profile);
vel_vec = NaN(1, num_bins);
pow_vec = NaN(1, num_bins);
snr_vec = NaN(1, num_bins);
for r = 1:num_bins
	if ~isempty(profile(r).velocity) && ~isnan(profile(r).velocity)
		vel_vec(r) = profile(r).velocity;
	end
	if ~isempty(profile(r).power) && ~isnan(profile(r).power)
		pow_vec(r) = profile(r).power;
	end
	if ~isempty(profile(r).snr_db) && ~isnan(profile(r).snr_db)
		snr_vec(r) = profile(r).snr_db;
	end
end
beam.a_params.ime_velocity = vel_vec;
beam.a_params.ime_power = pow_vec;
beam.a_params.ime_snr_db = snr_vec;

new_beam = beam;
end
