function u_gap = palghat_gap(h, u_llj, cfg)
arguments (Input)
	h (1, :) double % height bins
	u_llj (1, :) double % low-level jet zonal velocity profile
	% Palghat Gap Funneling
	cfg.pg_gamma_funnel double = 0.45; % [ ] 45% wind speed increase from Bernoulli funneling through the mountain pass.
	cfg.pg_pc_elev double = 0.6        % [km] Pass core elevation
	cfg.pg_pc_thick double = 0.5       % [km] Pass core vertical thickness.
end
arguments (Output)
	u_gap (1, :) double
end
% Palghat Gap Funneling (low-level acceleration)
u_gap = u_llj .* (1 + cfg.pg_gamma_funnel * exp(-((h - cfg.pg_pc_elev) / cfg.pg_pc_thick).^2));
end
