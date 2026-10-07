function w_plumes = convective_plumes(h, cfg)
arguments (Input)
	h (1, :) double % height bins
	% Atmospheric Jitter & Thermal Convection
	cfg.plume_count double = 4     % [ ] Number of random convective updrafts/downdrafts
	cfg.plume_max_alt double = 6.0 % [km] Maximum altitude ceiling for thermal plumes
end
arguments (Output)
	w_plumes (1, :) double
end
% Random Convective Plumes in Lower Troposphere
z = h(:);
N = length(z);
w_plumes_col = zeros(N, 1);
for p = 1:cfg.plume_count
	z_center = 0.8 + rand() * (cfg.plume_max_alt - 0.8);
	w_peak = (rand() - 0.3) * 2.5;
	w_width = 0.2 + rand() * 0.4;
	w_plumes_col = w_plumes_col + w_peak * exp(-((z - z_center)/w_width).^2);
end
w_plumes = w_plumes_col';
end
