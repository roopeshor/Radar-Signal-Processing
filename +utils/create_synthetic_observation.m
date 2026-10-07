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
	cfg.altitudeRange = "middle"
	% Destination filepath to save synthetic .raw binary file.
	cfg.filepath string = ""

	% spectrum broadening
	cfg.sigma_v = ""
	% SNR array across range bins.
	cfg.SNR (1, :) double = []
	% width of DC component across range bins.
	cfg.sigma_dc (1, :) double = []
	% Flag to add complex Gaussian noise to IQ series.
	cfg.add_iq_noise logical = true
	% additional dc offset. this fraction of peak value of spectrum is added to signal in time domain
	cfg.dc_rel_power double = 0
	% list of height bin and bright band widths per peam
	cfg.bright_bands struct = struct([])
	cfg.sigma_turb_base (1, 1) double = 0.2
	cfg.sigma_chi (1, 1) double = 0.2
end
arguments (Output)
	% Synthesized Observation object populated with 5 beams and reference profiles.
	obj Observation
end

Headers = RadarData.empty(0, 5);
H = utils.create_synthetic_beamheader(headerFields=cfg.headerFields);
range_res = 3e8 * (H.m_fBaudLength_us * 1e-6) / 2;
z = H.m_fWindow1StartHeight + (0:H.m_sNumOfRangeBins-1)' * range_res;

DBS_V = 3.0e8 / 205e6 / 2.0;

for k = 1:5
	cfg.headerFields.m_sCurrentBeamCnt = k - 1;
	H = utils.create_synthetic_beamheader(headerFields=cfg.headerFields, altitudeRange=cfg.altitudeRange);
	Headers(k) = RadarData(H);
	vr = utils.compute_radial_velocity(u, v, w, H.m_fAzimuth, H.m_fOffZenith);
	sv = cfg.sigma_v;
	if (class(sv) == "string")
		sv = utils.compute_spectrum_broadening(z, u, v, w, vr, cfg.sigma_turb_base, cfg.sigma_chi);
	end
	Headers(k).ref_M1 = - vr / DBS_V;
	bb = [];
	if (isfield(cfg.bright_bands, Headers(k).direction))
		bb = cfg.bright_bands.(Headers(k).direction);
	end
	Headers(k).BeamData = utils.synthesize_iq_data(...
		vr           = vr,              ...
		Header       = H,               ...
		spec_w       = sv,      ...
		SNR          = cfg.SNR,         ...
		add_iq_noise = cfg.add_iq_noise, ...
		dc_rel_power = cfg.dc_rel_power, ...
		sigma_dc     = cfg.sigma_dc, ...
		bright_bands = bb ...
		);
end

if cfg.filepath ~= ""; utils.write_raw_file(Headers, cfg.filepath); end

obj = Observation(Headers);

obj.ref_height = z;
obj.ref_U = u;
obj.ref_V = v;
obj.ref_W = w;

end
