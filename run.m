filepath = fullfile("Data" , "Mode_2", "EXP_DBS_CH4_01Jun2025_18_04_28");
disp("Processing file: " + filepath);

% Define function handles for this run
obs = Observation(filepath);

N = obs.north;
S = obs.south;
E = obs.east;
W = obs.west;
V = obs.vertical;

N.spectra = mccf.compute_mccf_spectra(N);
S.spectra = mccf.compute_mccf_spectra(S);
E.spectra = mccf.compute_mccf_spectra(E);
W.spectra = mccf.compute_mccf_spectra(W);
V.spectra = mccf.compute_mccf_spectra(V);

% N.denoised_spectra = simple.denoise_beam(N);
% S.denoised_spectra = simple.denoise_beam(S);
% E.denoised_spectra = simple.denoise_beam(E);
% W.denoised_spectra = simple.denoise_beam(W);
% V.denoised_spectra = simple.denoise_beam(V);

N.denoised_spectra = N.spectra;
S.denoised_spectra = S.spectra;
E.denoised_spectra = E.spectra;
W.denoised_spectra = W.spectra;
V.denoised_spectra = V.spectra;

%% Doppler Spectra and Moments
figure("Name", "Spectra");

vmax = utils.compute_max_velocity(...
	N.m_fIntrPulsePeriod_us, ...
	N.m_sNumOfCohIntegrations ...
);
h_start = N.start_height / 1000;
h_end = N.end_height / 1000;

[N.M0, N.M1, N.M2, N.algorithm_parameters] = mccf.compute_mccf_moments(N);
[E.M0, E.M1, E.M2, E.algorithm_parameters] = mccf.compute_mccf_moments(E);
[W.M0, W.M1, W.M2, W.algorithm_parameters] = mccf.compute_mccf_moments(W);
[S.M0, S.M1, S.M2, S.algorithm_parameters] = mccf.compute_mccf_moments(S);
[V.M0, V.M1, V.M2, V.algorithm_parameters] = mccf.compute_mccf_moments(V);

N.M1 = medfilt1(N.M1, 5);
E.M1 = medfilt1(E.M1, 5);
W.M1 = medfilt1(W.M1, 5);
S.M1 = medfilt1(S.M1, 5);
V.M1 = medfilt1(V.M1, 5);

h = utils.compute_height_ranges(...
	h_start,...
	h_end,...
	N.m_sNumOfRangeBins ...
);

visualize_spectra(...
	N.denoised_spectra, ...
	{N.M1 * obs.DBS_Factor_V, N.ref_M1}, ...
	1, "North", ...
	h, vmax, h_start, h_end ...
)
visualize_spectra(...
	S.denoised_spectra, ...
	{S.M1 * obs.DBS_Factor_V, S.ref_M1}, ...
	2, "South", ...
	h, vmax, h_start, h_end ...
)
visualize_spectra(...
	E.denoised_spectra, ...
	{E.M1 * obs.DBS_Factor_V, E.ref_M1}, ...
	3, "East", ...
	h, vmax, h_start, h_end ...
)
visualize_spectra(...
	W.denoised_spectra, ...
	{W.M1 * obs.DBS_Factor_V, W.ref_M1}, ...
	4, "West", ...
	h, vmax, h_start, h_end ...
)
visualize_spectra(...
	V.denoised_spectra, ...
	{V.M1 * obs.DBS_Factor_V, V.ref_M1}, ...
	5, "Vertical", ...
	h, vmax, h_start, h_end ...
)


%% UVW
figure("Name", "UVW")
plot_compared_ref((E.M1 - W.M1) * obs.DBS_Factor_H, obs.ref_U, 1, h, "Zonal (U)")
plot_compared_ref((S.M1 - N.M1) * obs.DBS_Factor_H, obs.ref_V, 2, h, "Meridional (V)")
plot_compared_ref(-V.M1 * obs.DBS_Factor_V, obs.ref_W, 3, h, "Vertical (W)")


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

function visualize_spectra(spectra, M1s, idx, direction, heights, max_velocity, start_height, end_height)
arguments
	spectra (:, 1024) double
	M1s (1, :) cell
	idx double
	direction string
	heights (:, 1) double
	max_velocity = 30
	start_height = 0 % in km
	end_height = 8 % in km
end

subplot(1,5,idx);
warning('off', 'MATLAB:log:logOfZero');
x_bounds = [-max_velocity, max_velocity]/4;
imagesc( ...
	x_bounds, ...
	[start_height, end_height], ...
	10 * log10(spectra) ...
);
hold on;
plot(M1s{1}, heights, 'w-', 'LineWidth', 1, 'Color', "red");
plot(M1s{2}, heights, 'w-', 'LineWidth', 1, 'Color', "black");
xlim(x_bounds);
hold off;
set(gca, 'YDir', 'normal');
colormap('Parula');

% 3. Plot to the second axes
xlabel('Doppler Velocity (m/s)');
ylabel('Altitude (km)');
title(direction);

end
