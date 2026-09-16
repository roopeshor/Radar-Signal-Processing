function obj = create_synthetic_observation(u, v, w, cfg)
% UTILS.CREATE_SYNTHETIC_OBSERVATION Synthesizes an Observation object with ground-truth wind profiles.
%
%   Generates 5-beam IQ data cubes via Zrnic spectral simulation, sets reference moments and wind vector
%   profiles (u, v, w), and optionally writes out a .raw binary data file.

arguments (Input)
	% Zonal wind profile vector (m/s).
	u (1, :) double
	% Meridional wind profile vector (m/s).
	v (1, :) double
	% Vertical wind profile vector (m/s).
	w (1, :) double
	% Custom header property overrides.
	cfg.headerFields = struct()
	% Destination filepath to save synthetic .raw binary file.
	cfg.filepath string = ""
	% SNR array across range bins.
	cfg.SNR (1, :) double = []
	% Spectral width parameter.
	cfg.spec_w (1, 1) double = 0.3
	% Flag to add complex Gaussian noise to IQ series.
	cfg.add_iq_noise logical = true
end
arguments (Output)
	% Synthesized Observation object populated with 5 beams and reference profiles.
	obj Observation
end

Headers = RadarData.empty(0, 5);

for k = 1:5
	cfg.headerFields.m_sCurrentBeamCnt = k - 1;

	H = utils.create_synthetic_beamheader(headerFields=cfg.headerFields);
	vr = utils.compute_radial_velocity(u, v, w, H.m_fAzimuth, H.m_fOffZenith);

	Headers(k) = RadarData(H);
	DBS_V = 3.0e8 / 205e6 / 2.0;
	Headers(k).ref_M1 = - vr / DBS_V;
	Headers(k).BeamData = utils.synthesize_iq_data(...
		vr           = vr,              ...
		Header       = H,               ...
		SNR          = cfg.SNR,         ...
		spec_w       = cfg.spec_w,      ...
		add_iq_noise = cfg.add_iq_noise ...
		);
end

if cfg.filepath ~= ""; utils.write_raw_file(Headers, cfg.filepath); end

obj = Observation(Headers);

range_res = 3e8 * (H.m_fBaudLength_us * 1e-6) / 2;
obj.ref_height = H.m_fWindow1StartHeight + (0:H.m_sNumOfRangeBins-1)' * range_res;
obj.ref_U = u;
obj.ref_V = v;
obj.ref_W = w;

end
