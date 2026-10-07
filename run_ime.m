% nRangeBins = 173;
% [z, u, v, w] = generate_wind_profile(nRangeBins=nRangeBins, qbo_u=10, qbo_v=10);

% vel_factor = 3.0e8 / 205e6 / 2.0;
% DBS_Factor_V = vel_factor;
% DBS_Factor_H = vel_factor / (2 * sind(10));

% obs = synth.create_synthetic_observation(...
% 	u, v, w,...
% 	SNR          = 10 .^ (ones(1,nRangeBins) * 100), ...
% 	spec_w       = 0.1,                       ...
% 	add_iq_noise = false ...
% 	);

fn = fullfile("Data", "other", "EXP_DBS_CH4_29Jul2026_19_17_20");
obs = Observation(fn);
obs = obs.compute_spectra_with(@ime.compute_spectra);
obs = ime.remove_dc_from_beams(obs);
obs = ime.denoise_all_beams(obs);
obs = obs.compute_moments_with(@ime.compute_moments);

N = obs.north;
S = obs.south;
E = obs.east;
W = obs.west;
V = obs.vertical;

l = ["north", "east", "west", "south", "vertical"];
[y,x]   = size(obs.west.spectra);
figure("Name", "Spectra");
pli = 1;
for i = 3:5
	d = l(i);
	subplot(1,3, pli);
	pli = pli+1;
	obs_d = obs.(d).denoised_spectra;
	plt.plot_doppler_spectra(...
		spectra   = log10(obs_d),              ...
		comp_m    = obs.(d).M1 * obs.DBS_Factor_V, ...
		ref_m     = obs.(d).ref_M1 * obs.DBS_Factor_V, ...
		direction = obs.(d).direction,                 ...
		heights   = obs.heights,                           ...
		x_max     = obs.v_max                          ...
		)
end
colorbar;
figure
%% UVW Wind Vector Plotting
plt.plot_compared_M1(-(E.M1 - W.M1) * obs.DBS_Factor_H, obs.ref_U, 1, obs.heights, "Zonal (U)")
plt.plot_compared_M1(-(N.M1 - S.M1) * obs.DBS_Factor_H, obs.ref_V, 2, obs.heights, "Meridional (V)")
c_th = cosd(N.m_fOffZenith);
sum_M1 = E.M1 + W.M1 + N.M1 + S.M1;
calc_W = -obs.DBS_Factor_V * (c_th * sum_M1 + V.M1) / (4 * c_th^2 + 1);
plt.plot_compared_M1(calc_W, obs.ref_W, 3, obs.heights, "Vertical (W)")
