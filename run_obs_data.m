filepath = fullfile("Data", "other", "EXP_DBS_CH4_29Jul2026_19_22_59");
disp("Processing file: " + filepath);

obs = Observation(filepath);
obs = obs.compute_spectra_with(@mccf.compute_spectra);
obs = obs.apply_fx(@ime.compute_moments);

N = obs.north;
S = obs.south;
E = obs.east;
W = obs.west;
V = obs.vertical;

%% Doppler Spectra and Moments
figure("Name", "Spectra");

dirs = [N,S,E,W,V];

tiledlayout(1, 1);
for i = 1:1
	d = dirs(i);
	nexttile;
	plt.plot_doppler_spectra(...
		spectra   = 10*log10(abs(d.denoised_spectra).^2),                   ...
		direction = d.direction,                           ...
		comp_m    = d.M1 * obs.DBS_Factor_V,               ...
		heights   = obs.heights,                           ...
		x_max     = obs.v_max                    ...
		)
end

figure("Name", "UVW")
plt.plot_compared_M1(-(E.M1 - W.M1) * obs.DBS_Factor_H, obs.ref_U, 1, obs.heights, "Zonal (U)")
plt.plot_compared_M1(-(N.M1 - S.M1) * obs.DBS_Factor_H, obs.ref_V, 2, obs.heights, "Meridional (V)")

c_th = cosd(N.m_fOffZenith);
sum_M1 = E.M1 + W.M1 + N.M1 + S.M1;
calc_W = -obs.DBS_Factor_V * (c_th * sum_M1 + V.M1) / (4 * c_th^2 + 1);

plt.plot_compared_M1(calc_W, obs.ref_W, 3, obs.heights, "Vertical (W)")
