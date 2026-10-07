% put base file name here (without file extension)
filepath = fullfile("Data", "other", "EXP_DBS_CH4_29Jul2026_17_22_12");
disp("Processing file: " + filepath);

obs = Observation(filepath);

%% MCCF Method
obs = obs.compute_spectra_with(@simple.compute_spectra);
% obs = simple.HS_denoise_all_beams(obs);
obs = obs.compute_moments_with(@simple.compute_moments);

% obs = obs.compute_spectra_with(@simple.compute_spectra);
% obs = simple.HS_denoise_all_beams(obs);
% obs = obs.compute_moments_with(@simple.compute_moments);

N = obs.north;
S = obs.south;
E = obs.east;
W = obs.west;
V = obs.vertical;

%% Doppler Spectra and Moments
figure("Name", "Spectra");

dirs = [N,S,W,E,V];

for i = 1:5
	d = dirs(i);
	subplot(1, 5, i);
	utils.plot_doppler_spectra(...
		spectra   = 10*log10(d.spectra),   ...
		direction = d.direction,                 ...
		heights   = obs.heights,                           ...
		x_max     = obs.v_max                    ...
		)
end
% CN^2
% %% UVW
% figure("Name", "UVW")
% utils.plot_compared_M1(-(E.M1 - W.M1) * obs.DBS_Factor_H, obs.ref_U, 1, obs.heights, "Zonal (U)")
% utils.plot_compared_M1(-(N.M1 - S.M1) * obs.DBS_Factor_H, obs.ref_V, 2, obs.heights, "Meridional (V)")

% c_th = cosd(N.m_fOffZenith);
% sum_M1 = E.M1 + W.M1 + N.M1 + S.M1;
% calc_W = -obs.DBS_Factor_V * (c_th * sum_M1 + V.M1) / (4 * c_th^2 + 1);

% utils.plot_compared_M1(calc_W, obs.ref_W, 3, obs.heights, "Vertical (W)")
