function new_obs = remove_dc_from_beams(obs)
%ime.remove_dc_from_beams Removes DC ground clutter component from all beams in the Observation.

arguments (Input)
	obs Observation
end
arguments (Output)
	new_obs Observation
end

new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	new_obs.(dir) = ime.remove_dc(obs.(dir));
end
end
