function [u_llj, v_llj] = somali_jet(h, cfg)
arguments (Input)
	h (1, :) double % height bins
	% Low-Level Somali Jet - Onshore SW Monsoon flow
	cfg.sj_w double = 12       % [m/s] (zonal) onshore wind speeds of the SW monsoon jet
	cfg.sj_uv double = 14      % [m/s] (meridional) onshore wind speeds of the SW monsoon jet
	cfg.sj_center double = 1.5 % [km] Altitude of the jet core center.
	cfg.sj_s double = 0.8      % [km] Gaussian standard deviation controlling vertical thickness of the jet.
end
arguments (Output)
	u_llj (1, :) double
	v_llj (1, :) double
end
% Low-Level Somali Jet (~1.5 km peak) - Onshore SW Monsoon flow
u_llj = cfg.sj_w * exp(-((h - cfg.sj_center) / cfg.sj_s).^2);
v_llj = cfg.sj_uv * exp(-((h - cfg.sj_center) / cfg.sj_s).^2);
end
