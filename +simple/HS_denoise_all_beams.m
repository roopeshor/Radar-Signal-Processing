function new_obs = HS_denoise_all_beams(obs)
% SIMPLE.HS_DENOISE_ALL_BEAMS Batch denoises all beams in an Observation using Hildebrand-Sekhon noise subtraction.

arguments (Input)
	% Observation object containing all 5 DBS radar beams.
	obs Observation
end
arguments (Output)
	% Modified Observation object with denoised_spectra and noise_level fields populated.
	new_obs Observation
end

new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	[ds, nl] = simple.HS_denoise_beam(obs.(dir));
	new_obs.(dir).denoised_spectra = ds;
	new_obs.(dir).noise_level = nl;
end

end
