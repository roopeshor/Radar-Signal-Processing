filepath = fullfile("Data" , "EXP_DBS_CH4_29Jul2026_17_15_14");
disp("Processing file with MCCF: " + filepath);

% Define function handles for this run
spectra_func = @compute_mccf_spectra;
moments_func = @compute_mccf_moments;

obs = Observation(filepath);
% Process beams with custom MCCF spectra computing function


% Compute DBS factors
obs.DBS_Factor_H = compute_dbs_factor(beams.north.m_fOffZenith);
obs.DBS_Factor_V = compute_dbs_factor(beams.vertical.m_fOffZenith);

N = beams.north;
S = beams.south;
E = beams.east;
W = beams.west;
V = beams.vertical;

N = denoise_beam(N);
S = denoise_beam(S);
E = denoise_beam(E);
W = denoise_beam(W);
V = denoise_beam(V);

max_velocity = compute_max_velocity(...
	N.m_fIntrPulsePeriod_us, ...
	N.m_sNumOfCohIntegrations ...
);

%% Doppler Spectra
spectras = cat(3,...
	N.spectra,...
	S.spectra,...
	E.spectra,...
	W.spectra ...
);

visualize_spectra(...
	spectras,...
	["North", "South", "East", "West"], ...
	figsize = [2 2],...
	max_velocity = max_velocity, ...
	start_height = N.start_height,...
	end_height = N.end_height ...
);

%% Moments (Using MCCF)
N = moments_func(N);
E = moments_func(E);
W = moments_func(W);
S = moments_func(S);
V = moments_func(V);

N.M1 = medfilt1(N.M1, 5);
E.M1 = medfilt1(E.M1, 5);
W.M1 = medfilt1(W.M1, 5);
S.M1 = medfilt1(S.M1, 5);
V.M1 = medfilt1(V.M1, 5);

heights = compute_height_ranges(...
	N.start_height,...
	N.m_fBaudLength_us,...
	N.m_sNumOfRangeBins ...
);

figure("Name", "Moments (MCCF)")

function plot_compared_ref(calc, ref, idx, heights, title_, plots)
	if nargin < 6
		plots = 3;
	end
	subplot(1, plots, idx)
	plot(ref, heights); hold on
	plot(calc, heights);
	title(title_);
	legend(["ref", "calc"]);
end

plot_compared_ref(N.M1 * obs.DBS_Factor_V, N.ref_M1, 1, heights, "North")
plot_compared_ref(W.M1 * obs.DBS_Factor_V, W.ref_M1, 2, heights, "West")
plot_compared_ref(V.M1 * obs.DBS_Factor_V, V.ref_M1, 3, heights, "Vertical")

%% UVW (Using MCCF)
figure("Name", "UVW (MCCF)")
plot_compared_ref((E.M1 - W.M1) * obs.DBS_Factor_H, obs.ref_U, 1, heights, "Zonal (U)")
plot_compared_ref((N.M1 - S.M1) * obs.DBS_Factor_H, obs.ref_V, 2, heights, "Meridional (V)")
plot_compared_ref(V.M1 * obs.DBS_Factor_V, obs.ref_W, 3, heights, "Vertical (W)")
