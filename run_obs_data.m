% filepath = fullfile("Data/other/EXP_DBS_CH4_29Jul2026_19_21_31");
% filepath = fullfile("Data/other/EXP_DBS_CH4_29Jul2026_19_20_07");
filepath = fullfile("Data/other/EXP_DBS_CH4_29Jul2026_19_17_20");
disp("Processing file: " + filepath);

obs = Observation(filepath);

% % old method
% obs = simple.compute_all_spectra(obs);
% obs = simple.denoise_all_beams(obs);
% obs = simple.compute_all_moments(obs);

% MCCF Method
obs = mccf.compute_all_spectra(obs);
obs = simple.denoise_all_beams(obs);
obs = mccf.compute_all_moments(obs);

% obs = st.compute_all_spectra(obs);
% obs = st.compute_all_moments(obs);
% obs = mccf.compute_all_moments(obs);

N = obs.north;
S = obs.south;
E = obs.east;
W = obs.west;
V = obs.vertical;

h_start = N.start_height / 1000;
h_end = N.end_height / 1000;

%% Doppler Spectra and Moments
% figure("Name", "Spectra");

N.M1 = medfilt1(N.M1, 5);
E.M1 = medfilt1(E.M1, 5);
W.M1 = medfilt1(W.M1, 5);
S.M1 = medfilt1(S.M1, 5);
V.M1 = medfilt1(V.M1, 5);

h = utils.compute_height_ranges(h_start, h_end, N.m_sNumOfRangeBins);

dirs = [N,S,W,E,V];

for i = 1:2
	d = dirs(i);
	subplot(1, 2, i);
	utils.plot_doppler_spectra(...
		spectra   = log10(d.spectra),   ...
		comp_m    = d.M1 * obs.DBS_Factor_V,     ...
		ref_m     = d.ref_M1 * obs.DBS_Factor_V, ...
		direction = d.direction,                 ...
		heights   = h,                           ...
		x_max     = obs.v_max                    ...
		)
end

% %% UVW
figure("Name", "UVW")
plot_compared_ref(-(E.M1 - W.M1) * obs.DBS_Factor_H, obs.ref_U, 1, h, "Zonal (U)")
plot_compared_ref(-(N.M1 - S.M1) * obs.DBS_Factor_H, obs.ref_V, 2, h, "Meridional (V)")
c_th = cosd(N.m_fOffZenith);
sum_M1 = E.M1 + W.M1 + N.M1 + S.M1;
calc_W = -obs.DBS_Factor_V * (c_th * sum_M1 + V.M1) / (4 * c_th^2 + 1);

plot_compared_ref(calc_W, obs.ref_W, 3, h, "Vertical (W)")


%% Functions

function plot_compared_ref(calc, ref, idx, heights, title_, plots)
if nargin < 6
	plots = 3;
end
subplot(1, plots, idx)
plot(ref, heights); hold on
plot(calc, heights);
xlim([min(ref) * 2, max(ref) * 2]);
xlabel("wind velocity (m/s)")
ylabel("height (km)")
title(title_);
legend(["ref", "calc"]);
end
