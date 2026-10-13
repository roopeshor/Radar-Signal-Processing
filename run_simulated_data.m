% Synthesizes raw ST Radar data from randomly generated data
% and runs all variations of pipelines

params_file = fopen(fullfile("exp", "params_file.txt"), 'at');
MSE = fopen(fullfile("exp", "MSE.tsv"), 'at');
bench = fopen(fullfile("exp", "bench.tsv"), 'at');
write_file = true;
if params_file == -1 || MSE == -1 || bench == -1
	error('File could not be opened.');
end
if write_file
	fprintf(bench, "experiment_id\tmethod\ttime(ms)\n");
end
if write_file
	fprintf(MSE, "experiment_id\tmethod\tdirection\tMSE\n");
end

for exp_idx=1:500
	disp("============== Exp: " + exp_idx + " ==============")

	alts = ["lower", "middle", "upper"];
	stripesD = struct("lower", 4, "middle", 3, "upper", 2);
	headData = BeamHeader.empty(0, 5);
	altitude_range = alts(randi(3));

	params = struct(...
		kt_tlpeak     = rand() * 5 + 10,        ...
		kt_vaf        = rand()/ 5 + 0.1,        ...
		kt_bf         = rand() * 5 + 1,         ...
		kt_maxT       = rand() * 2 + .5,        ...
		sj_center     = rand() * 2 + 1,         ...
		sj_uv         = (rand() - .5) * 10,     ...
		tej_u         = (rand() - .5) * 30,     ...
		tej_v         = (rand() - .5) * 30,     ...
		tej_alt       = rand() * 10 + 2,        ...
		qbo_lambda    = (rand() * 10) + 5,      ...
		qbo_u         = (rand() - .5) * 20,     ...
		qbo_v         = (rand() - .5) * 20,     ...
		gw_nmodes     = round(rand() * 20) + 5, ...
		gw_amp        = rand() * 2 + 1,         ...
		plume_count   = round(rand() * 5) + 1,  ...
		plume_max_alt = rand() * 3 + 5,         ...
		bg_z0_m       = (rand() + .5) / 100,    ...
		gw_damp_scale = rand() * 10 + 1,        ...
		qbo_alt       = rand() * 10 + 5,        ...
		bg_blh        = rand() + 1             ...
		);


	for i=1:5
		headData(i) = synth.create_synthetic_beamheader(...
			headerFields = struct("m_sCurrentBeamCnt", i - 1), ...
			altitudeRange=altitude_range ...
			);
	end
	h_start = headData(1).m_fWindow1StartHeight/1000;
	h_end = headData(1).m_fWindow1EndHeight/1000;
	nRangeBins = headData(1).m_sNumOfRangeBins;
	nStripes  = round(max(stripesD.(altitude_range), randn() * stripesD.(altitude_range) + 1));
	skip_dist = round((nRangeBins - max(10, nStripes * 2)) / nStripes);
	perBinCnt = max(stripesD.(altitude_range)-1, round(abs(rand(1, nStripes)) * 3));
	bands= [];
	for i = 1:nStripes
		start_idx = (i - 1) * skip_dist + round(min(skip_dist - perBinCnt(i), rand() * skip_dist/3));
		sw = max(5, abs(randn(1, perBinCnt(i) + 1) * 6 + 4));
		idxs = start_idx + (1:(perBinCnt(i) + 1));
		bds = [idxs', sw'];
		bands = [bands; bds];
	end
	ps = namedargs2cell(params);
	[z, u, v, w] = synth.generate_wind_profile( ...
		"nRangeBins",  nRangeBins,      ...
		"start_height",  h_start,         ...
		"end_height",  h_end,           ...
		ps{:} ...
		);
	params.gc_rel_power  = rand() / 200 + 0.0005;
	params.bands  = bands;
	params.altitude_range  = altitude_range;
	obs_base = synth.create_synthetic_observation(...
		u, v, w,...
		SNR          = 10 .^ (linspace(50, -35, nRangeBins)/10), ...
		dc_rel_power = .2,                                     ...
		gc_rel_power = params.gc_rel_power, ...
		headerFields = headData,                                 ...
		bright_bands = struct(...
		"north", bands, ...
		"south", bands, ...
		"east", bands, ...
		"west", bands ...
		) ...
		);
	if write_file
		fprintf(params_file,"%d: %s\n", exp_idx, jsonencode(params));
	end

	%%%%%% mccf %%%%%%%
	obs_mccf = obs_base;
	tic;
	obs_mccf = obs_mccf.apply_beam_fx(@mccf.compute_all_params, wind_shear=1, win_coeff=2);
	t1 = toc;
	plt_res(obs_mccf, "mccf", exp_idx, params, t1, MSE, bench, write_file);

	%%%%%% ime %%%%%%%
	obs_ime = obs_base;
	obs_ime = obs_ime.apply_beam_fx(@ime.compute_beam_spectra);
	obs_ime = obs_ime.apply_beam_fx(@ime.denoise_beam);
	tic;
	obs_ime = obs_ime.apply_beam_fx(@ime.estimate_params, vel_axis=obs_ime.velocities);
	t1 = toc;
	plt_res(obs_ime, "ime", exp_idx, params, t1, MSE, bench, write_file);
	clear obs_ime;

	%%%%%% simple %%%%%%%
	obs_simp = obs_base;
	tic;
	obs_simp = obs_simp.apply_beam_fx(@simple.compute_beam_spectra);
	obs_simp = obs_simp.apply_beam_fx(@simple.denoise_beam);
	obs_simp = obs_simp.apply_beam_fx(@simple.compute_moments);
	t1 = toc;
	plt_res(obs_simp, "simple", exp_idx, params, t1, MSE, bench, write_file);
	clear obs_simp;

	%%%%%% MC+ime denoiser+ime moment estimator %%%%%%%
	obs_hyb = obs_base;
	tic;
	obs_hyb = obs_hyb.apply_beam_fx(@mccf.compute_beam_spectra);
	obs_hyb = obs_hyb.apply_beam_fx(@ime.denoise_beam);
	obs_hyb = obs_hyb.apply_beam_fx(@ime.estimate_params, vel_axis=obs_hyb.velocities);
	t1 = toc;
	plt_res(obs_hyb, "mc+den+ime", exp_idx, params, t1, MSE, bench, write_file);
	clear obs_hyb;

	%%%%%% MC+ime moment estimator %%%%%%%
	obs_hyb2 = obs_base;
	tic;
	obs_hyb2 = obs_hyb2.apply_beam_fx(@mccf.compute_beam_spectra);
	obs_hyb2 = obs_hyb2.apply_beam_fx(@ime.estimate_params, vel_axis=obs_hyb2.velocities);
	t1 = toc;
	plt_res(obs_hyb2, "mc+ime", exp_idx, params, t1, MSE, bench, write_file);

	clear alts stripesD headData altitude_range params h_start h_end nRangeBins nStripes skip_dist perBinCnt bands start_idx sw idxs bds ps obs_* ;
	close all;
end

function plt_res(obs_, name_, exp_idx, params, t, MSE, bench, write_file)
if write_file
	fprintf(bench, "%d\t%s\t%f\n", exp_idx, name_, t);
end
DO_plot=false; % if need to generate plots
for i = 1:5
	beam = obs_.(Data.directions(i));
	M = beam.M1;
	valid_idx = ~isnan(M);
	params.mse = immse(beam.ref_M1(valid_idx) * obs_.DBS_Factor, M(valid_idx));
	if write_file
		fprintf(MSE, "%d\t%s\t%s\t%f\n", exp_idx, name_, Data.directions(i), params.mse);
	end
	if DO_plot
		jsondcp = jsonencode(params);
		f = figure('Visible', 'off', 'Units', "pixels", 'Position', [0, 0, 800, 1100]);
		theme(f, 'light');
		data = 20*log10(abs(beam.spectra));
		plt.plot_doppler_spectra(...
			spectra   = data,                           ...
			direction = beam.direction,                 ...
			ref_m     = -beam.ref_M1 * obs_.DBS_Factor, ...
			comp_m    = -beam.M1 * obs_.DBS_Factor,                             ...
			heights   = obs_.heights/1000,              ...
			x_max     = obs_.v_max          ...
			)
		colorbar
		clim([-150,0]);
		set(groot, 'defaultAxesFontSize', 20)
		imwrite(getframe(f).cdata, ...
			"plots/" + exp_idx + "_"+name_+"_" + i + ".png", ...
			'Comment', jsondcp ...
			);
		close(f)
	end
end
end
