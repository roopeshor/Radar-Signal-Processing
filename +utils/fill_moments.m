function new_obs = fill_moments(obs, fx)
%fill_spectras computes moments of all beams in the observation with given moment computer function
arguments (Input)
	obs Observation
	% function to apply on all beams
	fx function_handle
end
new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	new_obs.(dir) = fx(obs.(dir));
end
end
