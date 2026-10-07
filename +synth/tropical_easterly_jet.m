function [u_tej, v_tej] = tropical_easterly_jet(h, cfg)
arguments (Input)
	h (1, :) double % height bins
	% Tropical Easterly Jet (u_tej, v_tej)
	cfg.tej_u double = 35       % [m/s] (zonal) Strong easterly (westward) jet core speed near the tropopause.
	cfg.tej_v double = 3        % [m/s] (zonal) Strong easterly (westward) jet core speed near the tropopause.
	cfg.tej_alt double = 15.0   % [km] TEJ core altitude
	cfg.tej_vthick double = 2.5 % [km] TEJ core vertical layer thickness.
end
arguments (Output)
	u_tej (1, :) double
	v_tej (1, :) double
end
% Tropical Easterly Jet (~15 km peak)
u_tej = cfg.tej_u * exp(-((h - cfg.tej_alt) / cfg.tej_vthick).^2);
v_tej = cfg.tej_v * exp(-((h - cfg.tej_alt) / cfg.tej_vthick).^2);
end
