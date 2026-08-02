filepath = fullfile("Data" , "EXP_DBS_CH4_29Jul2026_17_15_14");
disp("Processing file: " + filepath);

obs = Observation(filepath);

N = denoise_beam(obs.north);
S = denoise_beam(obs.south);
E = denoise_beam(obs.east);
W = denoise_beam(obs.west);
V = denoise_beam(obs.vertical);

max_velocity = compute_max_velocity(...
	N.m_fIntrPulsePeriod_us, ...
	N.m_sNumOfCohIntegrations ...
);

%% Doppler Spectra

spectras = cat(3,...
	N.denoised_spectra,...
	S.denoised_spectra,...
	E.denoised_spectra,...
	W.denoised_spectra ...
);

visualize_spectra(...
	spectras,...
	["North", "South", "East", "West"], ...
	figsize = [2 2],...
	max_velocity = max_velocity, ...
	start_height = N.start_height,...
	end_height = N.end_height ...
);

%% Moments
N = compute_beam_moments(N);
E = compute_beam_moments(E);
W = compute_beam_moments(W);
S = compute_beam_moments(S);
V = compute_beam_moments(V);

N.M1 = medfilt1(N.M1, 5);
E.M1 = medfilt1(E.M1, 5);
W.M1 = medfilt1(W.M1, 5);
S.M1 = medfilt1(S.M1, 5);
V.M1 = medfilt1(V.M1, 5);
% W.M1(isoutlier(W.M1)) = 0;

heights = compute_height_ranges(...
	N.start_height,...
	N.m_fBaudLength_us,...
	N.m_sNumOfRangeBins ...
);

figure("Name", "Moments")

function plot_compared_ref(calc, ref, idx, heights, title_, plots)
	if nargin < 6
		plots = 3; % Set default if 'scale' is missing
	end
	subplot(1, plots, idx)
	plot(ref / max(abs(ref)), heights); hold on
	plot(calc / max(abs(calc)), heights);
	xlim([-1.1,1.1])
	title(title_);
	legend(["ref", "calc"]);
end

plot_compared_ref(N.M1, N.ref_M1, 1, heights, "North")
plot_compared_ref(W.M1, W.ref_M1, 2, heights, "West")
plot_compared_ref(V.M1, V.ref_M1, 3, heights, "Vertical")

%% UVW
figure("Name", "UVW")
plot_compared_ref(E.M1 - W.M1, obs.ref_U, 1, heights, "Zonal (U)")
plot_compared_ref(N.M1 - S.M1, obs.ref_V, 2, heights, "Meridional (V)")
plot_compared_ref(V.M1, obs.ref_W, 3, heights, "Vertical (W)")
