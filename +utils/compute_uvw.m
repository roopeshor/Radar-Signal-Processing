function obs = compute_uvw(obs)
	% computes uvw from moments
arguments (Input)
	obs Observation
end
arguments (Output)
	obs Observation
end

sum_M1 = obs.east.M1 + obs.west.M1 + obs.north.M1 + obs.south.M1;
cth = cosd(obs.north.m_fOffZenith);

obs.U = -(obs.east.M1 - obs.west.M1) * obs.DBS_Factor_H;
obs.V = -(obs.north.M1 - obs.south.M1) * obs.DBS_Factor_H;
obs.W = -obs.DBS_Factor * (cth * sum_M1 + obs.vertical.M1) / (4 * cth^2 + 1);

end
