function vr = compute_radial_velocity(u, v, w, az, oz)
theta = oz * pi / 180;
phi   = az * pi / 180;
vr = u .* sin(phi) .* sin(theta) + ...
	v .* cos(phi) .* sin(theta) + ...
	w .* cos(theta);
end
