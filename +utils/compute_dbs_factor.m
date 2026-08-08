function factor = compute_dbs_factor(off_zenith_angle)
	% compute_dbs_factor calculates the scaling factor to convert 
	% Doppler frequencies (Hz) into wind velocities (m/s).
	% 
	% For vertical beams (0 degrees), it returns the radial velocity factor.
	% For off-zenith beams, it returns the horizontal DBS geometric factor.

	arguments
		off_zenith_angle (1,1) double
	end

	radarFreq = 205e6;
	c = 299792458.0;
	wavelength = c / radarFreq;
	vel_factor = wavelength / 2;

	if off_zenith_angle == 0
		factor = vel_factor;
	else
		factor = vel_factor / (2 * sind(off_zenith_angle));
	end
end
