function u_bl = synoptic_bg(h, cfg)
arguments (Input)
	h (1, :) double % height bins
	% Synoptic Background Profile
	cfg.bg_z0_m double = 0.05 % [m] Surface roughness length for terrain.
	cfg.bg_ustar double = 0.3 % [m/s] Friction velocity representing surface stress.
	cfg.bg_kappa double = 0.4 % [ ] von Kármán constant.
	cfg.bg_blh double = 1.5   % [km] boundary layer height
end
arguments (Output)
	u_bl (1, :) double
end
% Synoptic Background Profile
% Smooth logarithmic boundary layer fading by 2 km
z_m = h * 1000;
u_bl = (cfg.bg_ustar / cfg.bg_kappa) * log((z_m + cfg.bg_z0_m) / cfg.bg_z0_m) .* exp(-h / cfg.bg_blh);
end
