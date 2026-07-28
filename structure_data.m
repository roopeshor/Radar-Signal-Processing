function [structure] = structure_data(filepath)

    dat = Read_data(filepath);

    structure = struct( ...
        "Vertical", [], ...
        "North", [], ...
        "West", [], ...
        "South", [], ...
        "East", [] ...
    );

    for i = 1:5
        beam = dat(i);
        direction = get_beam_direction(beam.m_fAzimuth, beam.m_fOffZenith);
        beam.direction = direction;
        [denoised_spectra, spectra, noise_level] = process_radar_data(beam.BeamData);
        beam.denoised_spectra = denoised_spectra;
        beam.spectra = spectra;
        beam.noise_level = noise_level;
        structure.(direction) = beam;
    end

end