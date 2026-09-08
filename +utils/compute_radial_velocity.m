function vr = compute_radial_velocity(u, v, w, az, oz)
	% computes component of wind velocity parallel to the direction of the radar beam
theta = oz * pi / 180;
phi   = az * pi / 180;
if (oz == 0)
	vr = w;
else
	vr = u .* sin(phi) .* sin(theta) + ...
		v .* cos(phi) .* sin(theta);
end
end
%            |<--sin(th)--> .
%            |             .
%            |            .
%            |           .
%            |          .
%            |         .
%            |        .
%            |       .
%            |      .
%            | (th) .
%            |_10__.
%            |   .
%            |  .
%            | .
%            |.
%
%
%                     |N(0) (phi)
%       meridional(v) |
%            ^        |
%            |        |
% (270)               |
%   W_________________|_______________E(90)
%                     |
%                     |  ___________>
%                     |    zonal(u)
%                     |
%                    S|
%                   (180)
%
%
