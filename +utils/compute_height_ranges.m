function ranges = compute_height_ranges(start_range, end_range, num_range_bins)
% UTILS.COMPUTE_HEIGHT_RANGES Computes linearly spaced altitude bin values across observation windows.

arguments (Input)
	% Starting observation window height (km or m).
	start_range (1,1) double
	% Ending observation window height (km or m).
	end_range (1,1) double
	% Total number of range bins.
	num_range_bins (1,1) double
end
arguments (Output)
	% Vector of altitude range bin heights.
	ranges (1,:) double
end

ranges = start_range + (0:(num_range_bins - 1)) * (end_range - start_range) / (num_range_bins - 1);
end
