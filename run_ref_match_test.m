filepath = fullfile("Data/other/EXP_DBS_CH4_29Jul2026_19_17_20");
disp("Processing file: " + filepath);

obs = Observation(filepath);

N = obs.north;
S = obs.south;
E = obs.east;
W = obs.west;
V = obs.vertical;

h_start = N.start_height / 1000;
h_end = N.end_height / 1000;

h = utils.compute_height_ranges(h_start, h_end, N.m_sNumOfRangeBins);

dirs = [N,S,W,E,V];
% %% UVW
figure("Name", "UVW")
plot_compared_ref((E.ref_M1 - W.ref_M1) * obs.DBS_Factor_H, obs.ref_U, 1, h, "Zonal (U)")
plot_compared_ref((S.ref_M1 - N.ref_M1) * obs.DBS_Factor_H, obs.ref_V, 2, h, "Meridional (V)")
theta = 10;
c_th = cosd(theta);
sum_M1 = E.ref_M1 + W.ref_M1 + N.ref_M1 + S.ref_M1;
calc_W = -obs.DBS_Factor_V * (c_th * sum_M1 + V.ref_M1) / (4 * c_th^2 + 1);

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
