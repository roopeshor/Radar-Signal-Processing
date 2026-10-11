function plot_compared_vel(cfg)
% plt.plot_compared_vel Plots calculated vs reference wind velocity profiles against altitude.

arguments (Input)
	% Computed velocity profile vector.
	cfg.calc (1, :) double
	% Reference velocity profile vector.
	cfg.ref (1, :) double
	% Subplot index.
	cfg.plotidx (1, 1) double
	% Altitude heights array.
	cfg.heights (1, :) double
	% Subplot title string.
	cfg.title string = ""
	% Total subplots count.
	cfg.subplots (1, 1) double = 3
end

subplot(1, cfg.subplots, cfg.plotidx)
plot(cfg.ref, cfg.heights); hold on
plot(cfg.calc, cfg.heights);
xlim([min(cfg.ref) * 2, max(cfg.ref) * 2]);
ylim([min(cfg.heights), max(cfg.heights)]);
xlabel("wind velocity (m/s)")
ylabel("height (km)")
title(cfg.title);
legend(["ref", "calc"]);
end
