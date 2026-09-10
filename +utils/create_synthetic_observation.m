function obj = create_synthetic_observation(u, v, w, cfg)
% create_synthetic_observation  Create an artificial observation data file from a wind velocity array.
%   Generates a synthetic ST Radar raw data and attaches relavent ground truth to create a observation
%   Zrnic method is used to synthesize I/Q time-series data. If basename is not empty,
%   it will store the synthetic data to a file if filepath is not empty

arguments
	u (1, :) double
	v (1, :) double
	w (1, :) double
	cfg.headerFields = struct()

	% filepath to write observation in a .raw file. Observation be written to file if this is not empty string
	cfg.filepath string = ""
	% snr array
	cfg.SNR (1, :) double = []
	% spectral width
	cfg.spec_w (1, 1) double = 0.3
	% whether to add I/Q noise
	cfg.add_iq_noise logical = true
end

Headers = RadarData.empty(0, 5);

for k = 1:5
	cfg.headerFields.m_sCurrentBeamCnt = k - 1;

	H = utils.create_synthetic_beamheader(headerFields=cfg.headerFields);
	vr = utils.compute_radial_velocity(u, v, w, H.m_fAzimuth, H.m_fOffZenith);

	Headers(k) = RadarData(H);
	DBS_V = 3.0e8 / 205e6 / 2.0;
	Headers(k).ref_M1 = vr / DBS_V;
	Headers(k).BeamData = utils.synthesize_iq_data(...
		vr           = vr,              ...
		Header       = H,               ...
		SNR          = cfg.SNR,         ...
		spec_w       = cfg.spec_w,      ...
		add_iq_noise = cfg.add_iq_noise ...
		);
end

% Write to file
if cfg.filepath ~= ""; utils.write_raw_file(Headers, cfg.filepath); end

obj = Observation(Headers);

range_res = 3e8 * (H.m_fBaudLength_us * 1e-6) / 2; % meters
obj.ref_height = H.m_fWindow1StartHeight + (0:H.m_sNumOfRangeBins-1)' * range_res;
obj.ref_U = u;
obj.ref_V = v;
obj.ref_W = w;

end
