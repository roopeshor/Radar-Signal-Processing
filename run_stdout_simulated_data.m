% Synthesizes raw ST Radar data from randomly generated data
% and runs all variations of pipelines

% executed in CLI as
% matlab -nodisplay -batch "run_stdout_simulated_data('exp0', 1, 100)"

function run_stdout_simulated_data(folder_name, loop_start, loop_end)
arguments
	folder_name string = "exp0"
	loop_start = 1
	loop_end = 2
end
%%%%% IO opers
res_folder = fullfile("simulated_run", folder_name);
if ~isfolder(res_folder)
	mkdir(res_folder);
end

params_file = fopen(fullfile(res_folder, "params_file.txt"), 'at');
MSE         = fopen(fullfile(res_folder, "MSE.tsv"), 'at');
corr_file   = fopen(fullfile(res_folder, "corr.tsv"), 'at');
bench       = fopen(fullfile(res_folder, "bench.tsv"), 'at');

SAVE_DATA = true;
% to save generate plots
SAVE_PLOTS=false;

if params_file == -1 || MSE == -1 || bench == -1 || corr_file == -1
	error('File could not be opened.');
end

if SAVE_DATA
	fprintf(bench, "experiment_id\tmethod\ttime(ms)\n");
	fprintf(MSE, "experiment_id\tmethod\tdirection\tMSE\n");
	fprintf(corr_file, "experiment_id\tmethod\tdirection\tCorrelation (R_12)\n");
end

fs_handle = struct(...
	"bench", bench, ...
	"MSE", MSE, ...
	"corr_file", corr_file, ...
	"write_file", SAVE_DATA ...
	);


%%%%%%%%% Iter loop
for exp_idx=loop_start:loop_end
	disp("============== Exp: " + exp_idx + " ==============")

	[obs_base, params] = gen_rand_data();
	stringified_param = jsonencode(params);
	if SAVE_DATA
		fprintf(params_file,"%d: %s\n", exp_idx, stringified_param);
	end

	%%%%%% ime %%%%%%%
	obs_ime = obs_base;
	tic;
	obs_ime = obs_ime.apply_beam_fx(@ime.compute_beam_spectra);
	obs_ime = obs_ime.apply_beam_fx(@ime.denoise_beam);
	obs_ime = obs_ime.apply_beam_fx(@ime.estimate_params, vel_axis=obs_ime.velocities);
	elapsed = toc;
	beam_valid_bin_masks = struct(...
		"north", ~isnan(obs_ime.north.M1) , ...
		"east", ~isnan(obs_ime.east.M1) , ...
		"west", ~isnan(obs_ime.west.M1) , ...
		"south", ~isnan(obs_ime.south.M1) , ...
		"vertical", ~isnan(obs_ime.vertical.M1) ...
		);
	plot_results(obs_ime, "ime", exp_idx, params, elapsed, beam_valid_bin_masks);
	clear obs_ime;

	%%%%%% mccf %%%%%%%
	obs_mccf = obs_base;
	tic;
	obs_mccf = obs_mccf.apply_beam_fx(@mccf.compute_all_params, wind_shear=1, win_coeff=2);
	elapsed = toc;
	plot_results(obs_mccf, "mccf", exp_idx, params, elapsed, beam_valid_bin_masks);


	%%%%%% simple %%%%%%%
	obs_simp = obs_base;
	tic;
	obs_simp = obs_simp.apply_beam_fx(@simple.compute_beam_spectra);
	obs_simp = obs_simp.apply_beam_fx(@simple.denoise_beam);
	obs_simp = obs_simp.apply_beam_fx(@simple.compute_moments);
	elapsed = toc;
	plot_results(obs_simp, "simple", exp_idx, params, elapsed, beam_valid_bin_masks);
	clear obs_simp;

	%%%%%% MC+ime denoiser+ime moment estimator %%%%%%%
	obs_hyb = obs_base;
	tic;
	obs_hyb = obs_hyb.apply_beam_fx(@mccf.compute_beam_spectra);
	obs_hyb = obs_hyb.apply_beam_fx(@ime.denoise_beam);
	obs_hyb = obs_hyb.apply_beam_fx(@ime.estimate_params, vel_axis=obs_hyb.velocities);
	elapsed = toc;
	plot_results(obs_hyb, "mc+den+ime", exp_idx, params, elapsed, beam_valid_bin_masks);
	clear obs_hyb;

	%%%%%% MC+ime moment estimator %%%%%%%
	obs_hyb2 = obs_base;
	tic;
	obs_hyb2 = obs_hyb2.apply_beam_fx(@mccf.compute_beam_spectra);
	obs_hyb2 = obs_hyb2.apply_beam_fx(@ime.estimate_params, vel_axis=obs_hyb2.velocities);
	elapsed = toc;
	plot_results(obs_hyb2, "mc+ime", exp_idx, params, elapsed, beam_valid_bin_masks);

	clear params obs_* ;
	close all;
end
	function [obs_base, params] = gen_rand_data()
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

		strip_cnt  = round(max(stripesD.(altitude_range), randn() * stripesD.(altitude_range) + 1));
		strip_gap = round((nRangeBins - max(10, strip_cnt * 2)) / strip_cnt);
		strips_per_bin = max(stripesD.(altitude_range)-1, round(abs(rand(1, strip_cnt)) * 3));
		strips = [];
		for i = 1:strip_cnt
			start_idx = (i - 1) * strip_gap + round(min(strip_gap - strips_per_bin(i), rand() * strip_gap/3));
			sw = max(5, abs(randn(1, strips_per_bin(i) + 1) * 6 + 4));
			idxs = start_idx + (1:(strips_per_bin(i) + 1));
			bds = [idxs', sw'];
			strips = [strips; bds];
		end
		param_cell = namedargs2cell(params);
		[~, u, v, w] = synth.generate_wind_profile( ...
			"nRangeBins",  nRangeBins,      ...
			"start_height",  h_start,         ...
			"end_height",  h_end,           ...
			param_cell{:} ...
			);
		params.gc_rel_power  = rand() / 200 + 0.0005;
		params.bands  = strips;
		params.altitude_range  = altitude_range;
		obs_base = synth.create_synthetic_observation(...
			u, v, w,...
			SNR          = 10 .^ (linspace(50, -35, nRangeBins)/10), ...
			dc_rel_power = .2,                                     ...
			gc_rel_power = params.gc_rel_power, ...
			headerFields = headData,                                 ...
			bright_bands = struct(...
			"north", strips, ...
			"south", strips, ...
			"east", strips, ...
			"west", strips ...
			) ...
			);
	end

	function plot_results(obs, method_name, exp_idx, params, t, beamMasks)
		if fs_handle.write_file
			fprintf(fs_handle.bench, "%d\t%s\t%f\n", exp_idx, method_name, t);
		end
		for idx = 1:5
			beam_dir = Data.directions(idx);
			alt_mask = beamMasks.(beam_dir);
			beam = obs.(beam_dir);
			M = beam.M1(alt_mask);
			ref = beam.ref_M1(alt_mask) * obs.DBS_Factor;

			params.mse = immse(ref, M);
			R = corrcoef(ref, M);
			params.corr = R(1, 2);

			if fs_handle.write_file
				fprintf(fs_handle.MSE, "%d\t%s\t%s\t%f\n", exp_idx, method_name, beam_dir, params.mse);
				fprintf(fs_handle.corr_file, "%d\t%s\t%s\t%f\n", exp_idx, method_name, beam_dir, params.corr);
			end

			if SAVE_PLOTS
				f = figure('Visible', 'off', 'Units', "pixels", 'Position', [0, 0, 800, 1100]);
				theme(f, 'light');
				data = 20*log10(abs(beam.spectra));
				plt.plot_doppler_spectra(...
					spectra   = data,                           ...
					direction = beam.direction,                 ...
					ref_m     = -beam.ref_M1 * obs.DBS_Factor, ...
					comp_m    = -beam.M1 * obs.DBS_Factor,                             ...
					heights   = obs.heights/1000,              ...
					x_max     = obs.v_max          ...
					)
				colorbar
				clim([-150,0]);
				set(groot, 'defaultAxesFontSize', 20)
				plt_file = fullfile(res_folder, "plots", exp_idx + "_"+method_name+"_" + idx + ".png");
				imwrite(getframe(f).cdata, plt_file, ...
					'Comment', stringified_param ...
					);
				close(f)
			end
		end
	end
end
