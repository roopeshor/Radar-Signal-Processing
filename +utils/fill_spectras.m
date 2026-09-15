function new_obs = fill_spectras(obs, fx)
%fill_spectras computes spectrum of all beams in the observation with given function
arguments (Input)
	obs Observation
	% function to apply on all beams
	fx function_handle
end
arguments (Output)
	new_obs Observation
end
new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	new_obs.(dir).spectra = fx(obs.(dir));
	new_obs.(dir).denoised_spectra = new_obs.(dir).spectra;
end
end
