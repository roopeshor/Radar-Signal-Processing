[z, u, v, w] = generate_wind_profile();
%% 6. Visualization
figure('Name', 'Corrected Western Ghats Wind Profile');

subplot(1,3,1);
plot(u, z, 'b', 'LineWidth', 1.2); hold on;
xlabel('Zonal Wind u (m/s)'); ylabel('Height (km)');
title('East-West Wind (u)'); grid on; legend('Total');

subplot(1,3,2);
plot(v, z, 'r', 'LineWidth', 1.2); hold on;
xlabel('Meridional Wind v (m/s)'); ylabel('Height (km)');
title('North-South Wind (v)'); grid on; legend('Total');

subplot(1,3,3);
plot(w, z, 'g', 'LineWidth', 1.2); hold on;
xlabel('Vertical Velocity w (m/s)'); ylabel('Height (km)');
title('Vertical Wind (w)'); grid on; legend('Total w');
