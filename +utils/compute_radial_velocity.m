function vr = compute_radial_velocity(u, v, w, az, oz)
% UTILS.COMPUTE_RADIAL_VELOCITY Projects 3D wind velocity vector (u, v, w) along the radar beam direction.
%
%   Calculates line-of-sight radial velocity vr = (u*sin(az) + v*cos(az))*sin(oz) + w*cos(oz)
%   given azimuth angle az (degrees) and off-zenith angle oz (degrees).

arguments (Input)
	% Zonal wind component profile (m/s).
	u (1, :) double
	% Meridional wind component profile (m/s).
	v (1, :) double
	% Vertical wind component profile (m/s).
	w (1, :) double
	% Beam azimuth angle in degrees (0=North, 90=East, 180=South, 270=West).
	az (1, 1) double
	% Beam off-zenith angle in degrees.
	oz (1, 1) double
end
arguments (Output)
	% Projected line-of-sight radial velocity profile (m/s).
	vr (1, :) double
end

if (oz == 0)
	vr = w;
else
	vr = (u .* sind(az) + v .* cosd(az)) .* sind(oz) + w .* cosd(oz);
end
end
