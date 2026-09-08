function obj = create_synthetic_observation(u, v, w, config)
% create_synthetic_observation  Create an artificial observation data file from a wind velocity array.
%   Generates a synthetic ST Radar raw data and attaches relavent ground truth to create a observation
%   Zrnic method is used to synthesize I/Q time-series data. If basename is not empty,
%   it will store the synthetic data to a file if filepath is not empty

arguments
	u (1, :) double
	v (1, :) double
	w (1, :) double
	config.headerFields = struct()

	% filepath to write observation in a .raw file. Observation be written to file if this is not empty string
	config.filepath string = ""
end

Headers = RadarData.empty(0, 5);

for k = 1:5
	config.headerFields.m_sCurrentBeamCnt = k - 1;

	H = utils.create_synthetic_beamheader(headerFields=config.headerFields);
	vr = utils.compute_radial_velocity(u, v, w, H.m_fAzimuth, H.m_fOffZenith);

	Headers(k) = RadarData(H);
	Headers(k).BeamData = utils.synthesize_iq_data(vr, H);
end

% Write to file
if config.filepath ~= ""; utils.write_raw_file(Headers, config.filepath); end

obj = Observation(Headers);

range_res = 3e8 * (H.m_fBaudLength_us * 1e-6) / 2; % meters
obj.ref_height = H.m_fWindow1StartHeight + (0:H.m_sNumOfRangeBins-1)' * range_res;
obj.ref_U = u;
obj.ref_V = v;
obj.ref_W = w;

end
