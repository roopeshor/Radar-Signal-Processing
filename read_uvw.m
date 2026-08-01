function [height, U, V, W] = read_uvw(path)
	% read_uvw reads verified uvw file and returns its columns
	arguments
		path string
	end

	if ~isfile(path)
		warning(path + " not found, returning empty array");
		height = [];
		U = [];
		V = [];
		W = [];
		return;
	end

	output = readtable( ...
		path, ...
		FileType='text', ...
		VariableNamingRule='preserve' ...
		);
	height = output.("Height (km)");
	U = output.("Zonal(U) (m/s)");
	V = output.("Meridional(V) (m/s)");
	W = output.("Vertical (W) (m/s)");
end
