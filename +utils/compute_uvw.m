function obs = compute_uvw(obs)
arguments (Input)
	obs Observation
end
arguments (Output)
	obs Observation
end
theta = deg2rad(obs.north.m_fOffZenith);

u = (obs.east.M1 - obs.west.M1) ./ (2 * sin(theta));
v = (obs.north.M1 - obs.south.M1) ./ (2 * sin(theta));
sum_M1 = obs.east.M1 + obs.west.M1 + obs.north.M1 + obs.south.M1;
cth = cosd(obs.north.m_fOffZenith);
w = obs.DBS_Factor * (cth * sum_M1 + obs.vertical.M1) / (4 * cth^2 + 1);

obs.U = u;
obs.V = v;
obs.W = w;
end
