function ranges = compute_height_ranges(start_range, end_range, num_range_bins)
arguments (Input)
	start_range (1,1) double % m_fWindow1StartHeight
	end_range (1,1) double % m_fWindow1EndHeight
	num_range_bins (1,1) double % m_sNumOfRangeBins
end
arguments (Output)
	ranges (1,:) double
end

% theta = 10;
% start_range_km = start_range / 1000;
% range_resolution_km = (299792458.0 * baud_length_us * 1e-6 / 2) / 1000;
ranges = start_range + (0:(num_range_bins - 1)) * (end_range - start_range) / (num_range_bins - 1);
% radar_height_km = 0.1603;
% ranges = (slant_ranges * cosd(theta)) - radar_height_km;
end
