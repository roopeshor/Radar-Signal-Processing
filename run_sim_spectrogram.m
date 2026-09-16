% This file was created to test if the raw file synthesizer is correctly creating the required raw file

filepath = fullfile("Data" , "other", "EXP_DBS_CH4_29Jul2026_16_23_15.raw");
disp("Processing file: " + filepath);

obs = Observation(filepath);
obs = utils.fill_spectras(obs, @simple.compute_spectra);

u = obs.ref_U;
v = obs.ref_V;
w = obs.ref_W;

synth = utils.create_synthetic_observation(u, v, w, headerFields=obs.north);

disp("Computing Spectra...");
synth = utils.fill_spectras(synth, @mccf.compute_spectra);

h_start = synth.west.start_height / 1000;
h_end   = synth.west.end_height / 1000;
[h,x]   = size(synth.west.spectra);
x_ticks = linspace(-synth.v_max, synth.v_max, x);
y_ticks = linspace(h_start, h_end, h);
l = ["north", "east", "west", "south", "vertical"];

for i = 1:5
	d = l(i);
	disp(d + ", raw: beam" + string(obs.(d).m_sCurrentBeamCnt) + " : az" + string(obs.(d).m_fAzimuth) + " : oz" + string(obs.(d).m_fOffZenith))
	disp(d + ", syn: beam" + string(synth.(d).m_sCurrentBeamCnt) + " : az" + string(synth.(d).m_fAzimuth) + " : oz" + string(synth.(d).m_fOffZenith))

	figure
	subplot(1, 2, 1);
	syn_d = synth.(d).spectra;
	obs_d = obs.(d).spectra;
	utils.plot_doppler_spectra(...
		spectra   = log10(obs_d),              ...
		ref_m     = obs.(d).ref_M1 * obs.DBS_Factor_V, ...
		direction = obs.(d).direction,                 ...
		heights   = y_ticks,                           ...
		x_max     = obs.v_max                          ...
		)
	subplot(1, 2, 2);
	utils.plot_doppler_spectra(...
		spectra   = log10(syn_d),              ...
		ref_m     = synth.(d).ref_M1 * obs.DBS_Factor_V, ...
		direction = synth.(d).direction,                 ...
		heights   = y_ticks,                           ...
		x_max     = synth.v_max                          ...
		)
end
