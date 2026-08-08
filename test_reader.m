
%%% Just for testing whether the readers can work with wide variety of raw datas

files = dir("Data/*.raw");
str = struct( ...
	"ranges", [], ...
	"W1S", [], ...
	"W1E", [], ...
	"W2S", [], ...
	"W2E", [] ...
);

for i = 1:length(files)
	f = read_raw_file(fullfile(files(i).folder, files(i).name));
	% f = add_reference_data(f);
	str.ranges = [str.ranges; f(1).m_sNumOfRangeBins];
	str.W1S = [str.W1S; f(1).m_fWindow1StartHeight];
	str.W1E = [str.W1E; f(1).m_fWindow1EndHeight];
	str.W2S = [str.W2S; f(1).m_fWindow2StartHeight];
	str.W2E = [str.W2E; f(1).m_fWindow2EndHeight];
end

T = struct2table(str);
disp(T)
