function new_obs = fill_spectras(obs, fx)
% UTILS.FILL_SPECTRAS Batch applies a spectrum computation function handle across all beams in an Observation.

arguments (Input)
	% Observation object.
	obs Observation
	% Function handle for computing spectra from a RadarData beam.
	fx function_handle
end
arguments (Output)
	% Modified Observation object with populated spectra and denoised_spectra.
	new_obs Observation
end

new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	new_obs.(dir).spectra = fx(obs.(dir));
	new_obs.(dir).denoised_spectra = new_obs.(dir).spectra;
end
end
