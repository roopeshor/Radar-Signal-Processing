function plot_compared_M1(calc, ref, idx, heights, title_, plots)
% UTILS.PLOT_COMPARED_M1 Plots calculated vs reference wind velocity profiles against altitude.

arguments (Input)
	% Computed velocity profile vector.
	calc (1, :) double
	% Reference velocity profile vector.
	ref (1, :) double
	% Subplot index.
	idx (1, 1) double
	% Altitude heights array.
	heights (1, :) double
	% Subplot title string.
	title_ string = ""
	% Total subplots count.
	plots (1, 1) double = 3
end

subplot(1, plots, idx)
plot(ref, heights); hold on
plot(calc, heights);
xlim([min(ref) * 2, max(ref) * 2]);
ylim([min(heights), max(heights)]);
xlabel("wind velocity (m/s)")
ylabel("height (km)")
title(title_);
legend(["ref", "calc"]);
end
