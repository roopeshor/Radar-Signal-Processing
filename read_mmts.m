function [height, M0, M1, M2, SNR, noise_level] = read_mmts(path)
	% read_mmts reads verified mmts file and returns its columns
	arguments
		path string
	end

	if ~isfile(path)
		warning(path + " not found, returning empty array");
		height = [];
		M0 = [];
		M1 = [];
		M2 = [];
		SNR = [];
		noise_level = [];
		return;
	end

	output = readtable( ...
		path, ...
		FileType='text', ...
		VariableNamingRule='preserve' ...
		);
	height = output.("Height (km)");
	M0 = output.("M0 Total Power(dBm)");
	M1 = output.("M1 Mean Doppler (Hz)");
	M2 = output.("M2 Doppler Spread (Hz)");
	SNR = output.("SNR (dB)");
	noise_level = output.("Noise Level (dBm)");
end
