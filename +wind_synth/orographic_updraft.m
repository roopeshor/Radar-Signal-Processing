function w_oro = orographic_updraft(h, u_mean, cfg)
arguments (Input)
	h (1, :) double % height bins
	u_mean (1, :) double % mean zonal wind profile
	% Orographic Updraft
	cfg.ou_alpha_slope double = atan(1.5 / 30.0); % [ ] Western Ghats ridge terrain slope (1.5 km height rise over 30 km distance).
	cfg.ou_H_lift double = 3.5;                   % [km] Vertical decay scale
end
arguments (Output)
	w_oro (1, :) double
end
% Orographic Updraft
w_oro = max(0, u_mean) * tan(cfg.ou_alpha_slope) .* exp(-h / cfg.ou_H_lift);
end
