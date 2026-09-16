function new_obs = fill_moments(obs, fx)
% UTILS.FILL_MOMENTS Batch applies a moment computation function handle across all beams in an Observation.

arguments (Input)
	% Observation object.
	obs Observation
	% Function handle for computing spectral moments from a RadarData beam.
	fx function_handle
end
arguments (Output)
	% Modified Observation object with populated moments (M0, M1, M2, SNR).
	new_obs Observation
end

new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	new_obs.(dir) = fx(obs.(dir));
end
end
