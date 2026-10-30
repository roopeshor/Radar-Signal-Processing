% MSE & correlation analysis
clear; clc; close all;

folder = 'simulated_run/exp';
mse_file   = fullfile(folder, 'MSE.tsv');
corr_file   = fullfile(folder, 'corr.tsv');

MSE = readtable(mse_file, 'FileType','text', 'Delimiter','\t');
MSE.method    = string(MSE.method);
MSE.direction = string(MSE.direction);

CORR = readtable(corr_file, 'FileType','text', 'Delimiter','\t');
CORR.method    = string(CORR.method);
CORR.direction = string(CORR.direction);

methods = unique(MSE.method);
beams   = unique(MSE.direction);

meanMSE   = zeros(numel(methods), numel(beams));
medianMSE = zeros(numel(methods), numel(beams));

meanCORR   = zeros(numel(methods), numel(beams));
medianCORR = zeros(numel(methods), numel(beams));

% distribution of MSE & correlation for each beam
for m = 1:numel(methods)
	MSE_sub = MSE(MSE.method == methods(m), :);
	CORR_sub = CORR(CORR.method == methods(m), :);
	for b = 1:numel(beams)
		mse = MSE_sub.MSE(MSE_sub.direction == beams(b));
		meanMSE(m,b)   = mean(mse);
		medianMSE(m,b) = median(mse);

		corr = CORR_sub.Correlation(CORR_sub.direction == beams(b));
		meanCORR(m,b)   = mean(corr);
		medianCORR(m,b) = median(corr);
	end

end
% box plots
figure;
boxplot(CORR.Correlation, CORR.method);
ylabel('Correlation');
set(gca, 'YScale', 'log');
figure;
boxplot(MSE.MSE, MSE.method);
set(gca, 'YScale', 'log');
ylabel('MSE (log scale)'); xlabel('Method');

% mean MSE per beam for every algorithm
f = figure('Name','Summary');
theme(f, "light")
bar(meanMSE);
set(gca, 'XTickLabel', methods);
legend(beams, 'Location','northeastoutside');
ylabel('Mean MSE'); title('Mean MSE per beam, all algorithms'); grid on
exportgraphics(gcf, fullfile(folder, 'MSE_summary.svg'), 'Resolution', 400);

% mean CORR per beam for every algorithm
f = figure('Name','Summary');
theme(f, "light")
bar(meanCORR);
set(gca, 'YScale', 'log');
set(gca, 'XTickLabel', methods);
legend(beams, 'Location','northeastoutside');
ylabel('Mean CORR'); title('Mean CORR per beam, all algorithms'); grid on
exportgraphics(gcf, fullfile(folder, 'CORR_summary.svg'), 'Resolution', 400);
