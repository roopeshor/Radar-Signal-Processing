function new_beam = compute_candidate_peaks_beam(beam)
% IME.COMPUTE_CANDIDATE_PEAKS_BEAM Adaptive Doppler-window peak selection for a RadarData beam.
%
%   Computes prospective candidate peaks for a beam and stores the cell array in
%   beam.algorithm_parameters.ime_candidates_peaks.

arguments (Input)
	% Radar beam object containing spectra and noise parameters.
	beam RadarData
end
arguments (Output)
	% Modified RadarData beam populated with algorithm_parameters.ime_candidates_peaks.
	new_beam RadarData
end

spectra = beam.denoised_spectra;
noise_level = beam.noise_level;
if isempty(spectra)
	spectra = beam.spectra;
end

if isempty(noise_level)
	noise_level = ime.HS_noise_estimate(spectra, beam.m_sNumOfInCohIntegrations);
end

vel_axis = utils.compute_velocity_axis(beam);
candidate_peaks = ime.compute_candidate_peaks(spectra, noise_level, vel_axis);

if ~isstruct(beam.algorithm_parameters)
	beam.algorithm_parameters = struct();
end
beam.algorithm_parameters.ime_candidate_peaks = candidate_peaks;
new_beam = beam;
end
