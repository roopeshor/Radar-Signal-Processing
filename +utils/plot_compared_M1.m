function plot_compared_M1(calc, ref, idx, heights, title_, plots)
if nargin < 6
	plots = 3;
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
