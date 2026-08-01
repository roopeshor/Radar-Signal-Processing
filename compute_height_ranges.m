function ranges = compute_height_ranges(start_range_m, baud_length_us, num_range_bins)
	arguments
		start_range_m (1,1) double % m_fWindow1StartHeight
		baud_length_us (1,1) double % m_fBaudLength_us
		num_range_bins (1,1) double % m_sNumOfRangeBins
	end
	theta = 10;
	start_range_km = start_range_m / 1000;
	range_resolution_km = (299792458.0 * baud_length_us * 1e-6 / 2) / 1000;
	slant_ranges = start_range_km + (0:(num_range_bins - 1)) * range_resolution_km;
	radar_height_km = 0.1603;
	ranges = (slant_ranges * cosd(theta)) - radar_height_km;
end
