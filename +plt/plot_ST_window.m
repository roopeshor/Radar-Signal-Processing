function plot_ST_window(stw, v_max, heights, box_color)
arguments
	% ST window, array of tuple of (minIDX, maxIDX)
	stw (:, 2) double
	% max velocity
	v_max (1,1) double
	% height bins
	heights (1, :) double
	box_color = "#f0f"
end
stw = rescale(stw, -v_max, v_max, InputMin=1, InputMax=1024);
h = heights(2) - heights(1);

for i = 1:length(heights)
	x = stw(i, 1);
	y = heights(i);
	w = stw(i, 2) - x;
	line([-x-w, -x], [y, y], LineWidth=1, Color=box_color, HandleVisibility="off")
	line([-x-w, -x-w], [y-h/3, y+h/3], LineWidth=1, Color=box_color, HandleVisibility="off")
	line([-x, -x], [y-h/3, y+h/3], LineWidth=1, Color=box_color, HandleVisibility="off")
end
end
