function visualize_spectra(beams)
    % visualize_spectra Plots the tile of 2D Range-Doppler power spectra.
    
    figure('Position', [100, 100, 1000, 800]);
    
    for i = 1:length(beams)
        beam = beams(i);
        
        [beam_spectra, ~, ~] = process_radar_data(beam.BeamData);
        
        % Calculate max_velocity (Nyquist)
        radarFreq = 205e6;
        c = 299792458.0;
        wavelength = c / radarFreq;
        effective_sampling_time = beam.m_fIntrPulsePeriod_us * 1e-6 * beam.m_sNumOfCohIntegrations;
        max_velocity = wavelength / (4.0 * effective_sampling_time);
        
        start_height = beam.m_fWindow1StartHeight;
        end_height = beam.m_fWindow1EndHeight;
        
        % Calculate Power dB
        warning('off', 'MATLAB:log:logOfZero');
        power_db = 10 * log10(beam_spectra);
        warning('on', 'MATLAB:log:logOfZero');
        
        subplot(2, 3, i);
        
        extent_x = [-max_velocity, max_velocity];
        extent_y = [start_height, end_height];
        imagesc(extent_x, extent_y, power_db);
        % In MATLAB, imagesc puts y-axis top-down by default. 'YDir', 'normal' flips it.
        set(gca, 'YDir', 'normal');
        colormap('turbo');
        
        title(beam.direction);
        xlabel('Doppler Velocity (m/s)');
        ylabel('Altitude (km)');
        
        grid on;
        set(gca, 'GridColor', 'k', 'GridLineStyle', '--', 'GridAlpha', 0.3);
    end
end
