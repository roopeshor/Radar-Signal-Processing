%% run_sim.m
% Synthesizes raw ST Radar data from a prescribed wind profile
% and then runs the standard spectrum and moments processing pipeline.

basename = fullfile("Data", "other", "simulated_data");
disp("Synthesizing data to: " + basename);

% 1. Prescribe a wind profile
nRangeBins = 173;
% Generate some synthetic wind shears
% u = linspace(20, -5, nRangeBins)';
% v = linspace(-5, 25, nRangeBins)';
% w = 3 * sin(linspace(0, 4*pi, nRangeBins))';
[z, u, v, w] = generate_wind_profile();

% 2. Synthesize Raw Data and load Observation object
obs = Observation.synthetic(basename, u, v, w, nRangeBins=length(z));
% obs = Observation(basename);
% 3. Process Spectra and Moments
disp("Computing Spectra...");
obs = simple.compute_all_spectra(obs);
disp("Denoising Spectra...");
obs = simple.denoise_all_beams(obs);
disp("Computing Moments...");
obs = simple.compute_all_moments(obs);

N = obs.north;
S = obs.south;
E = obs.east;
W = obs.west;
V = obs.vertical;

%% Doppler Spectra and Moments Plotting
figure("Name", "Spectra");

vmax = utils.compute_max_velocity(...
	N.m_fIntrPulsePeriod_us, ...
	N.m_sNumOfCohIntegrations ...
);
h_start = N.start_height / 1000;
h_end = N.end_height / 1000;

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

visualize_spectra(N.denoised_spectra, {N.M1 * obs.DBS_Factor_V, N.ref_M1}, 1, "North", h, vmax, h_start, h_end)
visualize_spectra(S.denoised_spectra, {S.M1 * obs.DBS_Factor_V, S.ref_M1}, 2, "South", h, vmax, h_start, h_end)
visualize_spectra(E.denoised_spectra, {E.M1 * obs.DBS_Factor_V, E.ref_M1}, 3, "East", h, vmax, h_start, h_end)
visualize_spectra(W.denoised_spectra, {W.M1 * obs.DBS_Factor_V, W.ref_M1}, 4, "West", h, vmax, h_start, h_end)
visualize_spectra(V.denoised_spectra, {V.M1 * obs.DBS_Factor_V, V.ref_M1}, 5, "Vertical", h, vmax, h_start, h_end)

%% UVW Wind Vector Plotting
figure("Name", "UVW")
plot_compared_ref((E.M1 - W.M1) * obs.DBS_Factor_H, obs.ref_U, 1, h, "Zonal (U)")
plot_compared_ref((N.M1 - S.M1) * obs.DBS_Factor_H, obs.ref_V, 2, h, "Meridional (V)")
plot_compared_ref(V.M1 * obs.DBS_Factor_V, obs.ref_W, 3, h, "Vertical (W)")

%% Helper Plotting Functions
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
	subplot(1,5,idx);
	warning('off', 'MATLAB:log:logOfZero');
	x_bounds = [-max_velocity, max_velocity];
	imagesc(x_bounds, [start_height, end_height], 10 * log10(spectra));
	hold on;

    % Plot calculated and true moments
	if ~isempty(M1s{1}), plot(M1s{1}, heights, 'w-', 'LineWidth', 1, 'Color', "red"); end
	if ~isempty(M1s{2}), plot(M1s{2}, heights, 'w-', 'LineWidth', 1, 'Color', "black"); end

    xlim(x_bounds);
	hold off;
	set(gca, 'YDir', 'normal');
	colormap('Parula');

	xlabel('Doppler Velocity (m/s)');
	ylabel('Altitude (km)');
	title(direction);
end
