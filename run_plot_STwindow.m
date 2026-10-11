filepath = fullfile("Data", "other", "EXP_DBS_CH4_29Jul2026_16_20_28");
disp("Processing file: " + filepath);

obs = Observation(filepath);
obs = obs.apply_fx(@mccf.compute_all_params);
N = obs.north;

figure("Name", "ST Window");
i1 = 1;
i2 = 40;
vl = [-obs.v_max, obs.v_max]/3;
vidx = round(rescale(vl, 1, 1024, InputMin=-obs.v_max, InputMax=obs.v_max));
heights = obs.heights(i1:i2);

plt.plot_doppler_spectra(...
	spectra      = 10*log10(abs(N.spectra(i1:i2, vidx(1):vidx(2))).^2), ...
	comp_m       = N.M1(i1:i2) * obs.DBS_Factor_V,                        ...
	heights      = heights,                                               ...
	x_max        = vl(2),                                                 ...
	add_legend   = false,                                                 ...
	comp_m_color = "red" ...
	)

stw = N.algorithm_parameters.mccf_ST_W;
stw = rescale(stw, -obs.v_max, obs.v_max, InputMin=1, InputMax=1024);
h = obs.heights(2) - obs.heights(1);

for i = i1:i2
	x = stw(i, 1);
	y = obs.heights(i) - h/2;
	w = stw(i, 2) - x;
	rectangle(Position=[-x-w, y, w, h], LineWidth=1.5)
end
