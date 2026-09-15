%% run_sim.m
% Synthesizes raw ST Radar data from a prescribed wind profile
% and then runs the standard spectrum and moments processing pipeline.

nRangeBins = 173;
[z, u, v, w] = generate_wind_profile(nRangeBins=nRangeBins, qbo_u=10, qbo_v=10);

vel_factor = 3.0e8 / 205e6 / 2.0;
DBS_Factor_V = vel_factor;
DBS_Factor_H = vel_factor / (2 * sind(10));

obs = utils.create_synthetic_observation(...
	u, v, w,...
	SNR          = 10 .^ (linspace(100, -100, nRangeBins)/10), ...
	spec_w       = 0.1,                       ...
	add_iq_noise = true ...
	);
obs = utils.fill_spectras(obs, @simple.compute_spectra);
obs = simple.denoise_all_beams(obs);
obs = utils.fill_moments(obs, @simple.compute_moments);

N = obs.north;
S = obs.south;
E = obs.east;
W = obs.west;
V = obs.vertical;

%% Doppler Spectra and Moments Plotting

vmax = obs.v_max;
h_start = N.start_height / 1000;
h_end = N.end_height / 1000;


h = utils.compute_height_ranges(...
	h_start,...
	h_end,...
	N.m_sNumOfRangeBins ...
	);


l = ["north", "east", "west", "south", "vertical"];
h_start = obs.west.start_height / 1000;
h_end   = obs.west.end_height / 1000;
[y,x]   = size(obs.west.spectra);
y_ticks = linspace(h_start, h_end, y);
figure("Name", "Spectra");
pli = 1;
for i = 3:5
	d = l(i);
	subplot(1,3, pli);
	pli = pli+1;
	% already normalized
	obs_d = obs.(d).spectra;
	% the imagesec plots things as it is and sets the xlim
	% since x limit is velocity (based on fd * DBS_V)
	% the moments must also be scaled by DBS_V
	utils.plot_doppler_spectra(...
		spectra   = log10(obs_d),              ...
		comp_m    = obs.(d).M1 * obs.DBS_Factor_V, ...
		ref_m     = obs.(d).ref_M1 * obs.DBS_Factor_V, ...
		direction = obs.(d).direction,                 ...
		heights   = y_ticks,                           ...
		x_max     = obs.v_max                          ...
		)
end
colorbar;
%% UVW Wind Vector Plotting
figure("Name", "UVW")
utils.plot_compared_M1((E.M1 - W.M1) * obs.DBS_Factor_H, obs.ref_U, 1, h, "Zonal (U)")
utils.plot_compared_M1((N.M1 - S.M1) * obs.DBS_Factor_H, obs.ref_V, 2, h, "Meridional (V)")
utils.plot_compared_M1(V.M1 * obs.DBS_Factor_V, obs.ref_W, 3, h, "Vertical (W)")
