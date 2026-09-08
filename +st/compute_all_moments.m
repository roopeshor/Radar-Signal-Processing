function new_obs = compute_all_moments(obs)
%compute_all_moments computes moment of all beams in the observation
arguments (Input)
	obs Observation
end
arguments (Output)
	new_obs Observation
end
new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	new_obs.(dir) = st.compute_moments(obs.(dir));
end
end
