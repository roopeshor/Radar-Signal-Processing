function obs = getObservation(stuff, cfg)
arguments
	stuff = ''
	cfg.add_mmts logical = true
	cfg.add_uvw logical = true
end
is_str = isa(stuff, "string") || isa(stuff, "char");
if nargin == 0 || (is_str && stuff == "")
	% nothing is given, probably instantiated from readers or util functions
	return;
end
obs = Observation();
if is_str
	% given is filepath, use a file reader
	stuff = char(stuff);
	if (stuff(end-3:end) == ".raw")
		% already is pointing to raw
		obs.raw_filepath = stuff;
	else
		obs.raw_filepath = stuff + ".raw";
	end

	raw      = io.read_raw_file(obs.raw_filepath);
	ref_data = io.add_reference_data(...
		raw,...
		obs.raw_filepath,...
		add_mmts=cfg.add_mmts,...
		add_uvw=cfg.add_uvw...
		);

	obs.north    = ref_data.beam_struct.north;
	obs.east     = ref_data.beam_struct.east;
	obs.west     = ref_data.beam_struct.west;
	obs.south    = ref_data.beam_struct.south;
	obs.vertical = ref_data.beam_struct.vertical;

	obs.ref_height = ref_data.height;
	obs.ref_U = ref_data.U;
	obs.ref_V = ref_data.V;
	obs.ref_W = ref_data.W;

elseif isa(stuff, "RadarData") && length(stuff) == 5
	% Has already given raw data, probably from synthetic data constructor
	for k = 1:5
		obs.(stuff(k).direction) = stuff(k);
	end
else
	warning("No suitable input data found")
	return;
end

vel_factor = 3.0e8 / 205e6 / 2.0;
obs.DBS_Factor = vel_factor;
obs.DBS_Factor_H = vel_factor / (2 * sind(obs.north.m_fOffZenith));

obs.f_max = utils.compute_max_freq(obs.north.ipp_us, obs.north.n_coh);
obs.v_max = obs.f_max * vel_factor; % DBS_V
obs.start_height = obs.north.start_height;
obs.end_height = obs.north.end_height;
obs.nRangeBins = obs.north.nRangeBins;
obs.nFFT = obs.north.nFFT;
obs.ipp_us = obs.north.ipp_us;
obs.in_coh = obs.north.in_coh;
obs.n_coh = obs.north.n_coh;
obs.heights = utils.compute_height_bins(...
	obs.start_height, ...
	obs.end_height, ...
	obs.nRangeBins);
obs.velocities = utils.compute_velocity_bins(obs.nFFT, obs.ipp_us, obs.n_coh);
for dir = Data.directions
	obs.(dir).spectra = utils.get_original_spectrum(obs.(dir));
end

end
