clear; clc; close all;
fn = fullfile("Data", "other", "EXP_DBS_CH4_29Jul2026_19_17_20");
obs = getObservation(fn);
obs = apply_beam_fx(obs, @ime.compute_beam_spectra);
obs = apply_beam_fx(obs, @ime.denoise_beam);
obs = apply_beam_fx(obs, @ime.estimate_params, vel_axis=obs.velocities);
obs = utils.compute_uvw(obs);

tiledlayout(1, 5);
for i = 1:5
	d = obs.(Data.directions(i));
	nexttile;
	plt.plot_doppler_spectra(...
		spectra   = 10*log10(abs(d.spectra).^2), ...
		direction = d.direction,                          ...
		comp_m    = -d.M1 * obs.DBS_Factor,            ...
		ref_m     = -d.ref_M1 * obs.DBS_Factor,           ...
		heights   = obs.heights,                          ...
		x_max     = obs.v_max                    ...
		)
end
figure
plt.plot_compared_vel(calc=obs.U, ref=obs.ref_U, plotidx=1, heights=obs.heights, title="Zonal (U)")
plt.plot_compared_vel(calc=obs.V, ref=obs.ref_V, plotidx=2, heights=obs.heights, title="Meridional (V)")
plt.plot_compared_vel(calc=obs.W, ref=obs.ref_W, plotidx=3, heights=obs.heights, title="Vertical (W)")

disp('IME Processing Successfully Finished!');
