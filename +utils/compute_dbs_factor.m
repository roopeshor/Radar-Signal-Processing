function factor = compute_dbs_factor(off_zenith_angle)
	% compute_dbs_factor calculates the scaling factor to convert
	% Doppler frequencies (Hz) into wind velocities (m/s).
	% also converts negates sign for
	%
	% For vertical beams (0 degrees), it returns the radial velocity factor.
	% For off-zenith beams, it returns the horizontal DBS factor.

	arguments (Input)
		off_zenith_angle (1,1) double
	end
	arguments (Output)
		factor (1,1) double
	end

	vel_factor = 3.0e8 / 205e6 / 2.0;

	if off_zenith_angle == 0
		factor = vel_factor;
	else
		factor = vel_factor / (2 * sind(off_zenith_angle));
	end
end
