function ranges = compute_height_ranges(start_range, end_range, num_range_bins)
arguments (Input)
	start_range (1,1) double % m_fWindow1StartHeight
	end_range (1,1) double % m_fWindow1EndHeight
	num_range_bins (1,1) double % m_sNumOfRangeBins
end
arguments (Output)
	ranges (1,:) double
end

ranges = start_range + (0:(num_range_bins - 1)) * (end_range - start_range) / (num_range_bins - 1);
end
