
function dir_str = get_beam_direction(azimuth, offZenith)
    if offZenith == 0
        dir_str = 'Vertical';
        return;
    end
    azimuth_int = round(azimuth);
    switch azimuth_int
        case 0
            dir_str = 'North';
        case 90
            dir_str = 'West';
        case 180
            dir_str = 'South';
        case 270
            dir_str = 'East';
        otherwise
            dir_str = 'Unknown';
    end
end
