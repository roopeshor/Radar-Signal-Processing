% MSE analysis: which beam has the highest MSE in each algorithm
clear; clc; close all;

folder = './exp';
file   = fullfile(folder, 'MSE.tsv');   % change if your filename differs

T = readtable(file, 'FileType','text', 'Delimiter','\t');
T.method    = string(T.method);
T.direction = string(T.direction);

methods = ["mccf","ime","simple","mc+ime","mc+den+ime"];
beams   = ["north","east","west","south","vertical"];

meanMSE   = zeros(numel(methods), numel(beams));
medianMSE = zeros(numel(methods), numel(beams));

% distribution of MSE for each beam
for m = 1:numel(methods)
	sub = T(T.method == methods(m), :);

	f = figure('Name', char(methods(m)));
	theme(f, "light")
	boxchart(categorical(sub.direction, beams), sub.MSE); hold on
	for b = 1:numel(beams)
		v = sub.MSE(sub.direction == beams(b));
		meanMSE(m,b)   = mean(v);
		medianMSE(m,b) = median(v);
		plot(b, meanMSE(m,b), 'rd', 'MarkerFaceColor','r');   % mean marker
	end
	set(gca, 'YScale', 'log');          % MSE is heavily skewed (outliers up to ~40)
	ylabel('MSE (log scale)'); xlabel('Beam');
	title(sprintf('%s: MSE per beam (red = mean)', methods(m)));
	grid on

	exportgraphics(gcf, fullfile(folder, ...
		sprintf('MSE_%s.svg', matlab.lang.makeValidName(methods(m)))), 'Resolution', 400);
end

% mean MSE per beam for every algorithm
f = figure('Name','Summary');
theme(f, "light")
bar(meanMSE);
set(gca, 'XTickLabel', methods);
legend(beams, 'Location','northeastoutside');
ylabel('Mean MSE'); title('Mean MSE per beam, all algorithms'); grid on
exportgraphics(gcf, fullfile(folder, 'MSE_summary.svg'), 'Resolution', 400);

% Which beam is highest for each algorithm?
fprintf('\n%-12s %-28s %-28s\n', 'Algorithm', 'Highest mean MSE', 'Highest median MSE');
for m = 1:numel(methods)
	[vMean, iMean] = max(meanMSE(m,:));
	[vMed,  iMed]  = max(medianMSE(m,:));
	fprintf('%-12s %-8s (%.3f)%-12s %-8s (%.3f)\n', ...
		methods(m), beams(iMean), vMean, '', beams(iMed), vMed);
end

% Table of mean MSE (rows = algorithms, columns = beams)
MeanTable = array2table(meanMSE, 'RowNames', cellstr(methods), ...
	'VariableNames', cellstr(beams));
disp(MeanTable);
writetable(MeanTable, fullfile(folder, 'mean_MSE_table.csv'), 'WriteRowNames', true);
