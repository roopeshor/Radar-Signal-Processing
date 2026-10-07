function [u_qbo, v_qbo] = stratospheric_qbo(h, cfg)
arguments (Input)
	h (1, :) double % height bins
	% Stratospheric Quasi-Biennial Oscillation
	cfg.qbo_lambda double = 20 % [km] Vertical wavelength of alternating wind regimes in the stratosphere.
	cfg.qbo_u double = 8       % [m/s] Peak zonal amplitude of QBO phase shifts.
	cfg.qbo_v double = 3       % [m/s] Peak meridional amplitude of QBO phase shifts.
	cfg.qbo_alt double = 17    % [km] Altitude of QBO region
end
arguments (Output)
	u_qbo (1, :) double
	v_qbo (1, :) double
end
% Stratospheric QBO Regime (17 - 32 km)
qbo_envelope = 0.5 * (1 + tanh((h - cfg.qbo_alt) / 2.0));
u_qbo = cfg.qbo_u * sin(2 * pi * (h - cfg.qbo_alt) / cfg.qbo_lambda) .* qbo_envelope;
v_qbo = cfg.qbo_v * cos(2 * pi * (h - cfg.qbo_alt) / cfg.qbo_lambda) .* qbo_envelope;
end
