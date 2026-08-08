function dir_str = get_beam_direction(azimuth, offZenith)
arguments (Input)
	azimuth (1,1) double
	offZenith (1,1) double
end
arguments (Output)
	dir_str (1,1) string
end

if offZenith == 0
	dir_str = 'vertical';
	return;
end

switch round(azimuth)
	case 0
		dir_str = 'north';
	case 90
		dir_str = 'west';
	case 180
		dir_str = 'south';
	case 270
		dir_str = 'east';
	otherwise
		dir_str = 'Unknown';
end
end
