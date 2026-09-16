function new_obs = denoise_all_beams(obs)
% IME.DENOISE_ALL_BEAMS Denoises all beams in an Observation using the IME denoiser pipeline.

arguments (Input)
	obs Observation
end
arguments (Output)
	new_obs Observation
end

new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	new_obs.(dir) = ime.denoise_beam(obs.(dir));
end
end
