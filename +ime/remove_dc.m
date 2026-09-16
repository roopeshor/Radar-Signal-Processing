function new_beam = remove_dc(beam)
%ime.remove_dc  Removes ground clutter (DC bin) by linear interpolation.
arguments (Input)
	beam RadarData
end
arguments (Output)
	new_beam RadarData
end

if ~isempty(beam.denoised_spectra)
	Praw = beam.denoised_spectra;
elseif ~isempty(beam.spectra)
	Praw = beam.spectra;
else
	error('Beam spectra is empty.');
end
beam.denoised_spectra = remove_dc_matrix(Praw);
new_beam = beam;
end

function spectra = remove_dc_matrix(Praw)
[num_bins, nfft] = size(Praw);
spectra = Praw;
dc_idx = floor(nfft / 2) + 1;

for r = 1:num_bins
	spec_r = Praw(r, :);
	if dc_idx > 2 && dc_idx + 2 <= nfft
		left_val = spec_r(dc_idx - 2);
		right_val = spec_r(dc_idx + 2);
		avg_val = (left_val + right_val) / 2;
		spec_r((dc_idx-1):(dc_idx+1)) = avg_val;
	end
	spectra(r, :) = spec_r;
end
end
