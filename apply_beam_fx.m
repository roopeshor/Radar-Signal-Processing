function obs = apply_beam_fx(obs, fx, varargin)
% Batch applies a moments computating function across all beams in an Observation.
for dir = Data.directions
	obs.(dir) = fx(obs.(dir), varargin{:});
end
end
