function new_obs = compute_all_spectra(obs)
%compute_all_spectra computes spectrum of all beams in the observation
arguments (Input)
	obs Observation
end
arguments (Output)
	new_obs Observation
end
new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	new_obs.(dir).spectra = st.compute_spectra(obs.(dir));
end
end
