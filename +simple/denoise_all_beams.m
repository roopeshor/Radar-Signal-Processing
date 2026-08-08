function new_obs = denoise_all_beams(obs)
%denoise_all_beams denoises all beams in an observation using hildebrand sekhon method.

arguments (Input)
	obs Observation
end
arguments (Output)
	new_obs Observation
end
new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	new_obs.(dir).denoised_spectra = simple.denoise_beam(obs.(dir));
end

end
