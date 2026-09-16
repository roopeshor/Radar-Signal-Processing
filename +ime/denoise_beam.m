function new_beam = denoise_beam(beam)
%ime.denoiser  denoises given beam with HS noise subtraction and 5-point moving mean.
arguments (Input)
	beam RadarData
end
arguments (Output)
	new_beam RadarData
end
if ~isempty(beam.spectra)
	Praw = beam.spectra;
else
	error('Beam spectra is empty.');
end
M = beam.m_sNumOfInCohIntegrations;
[Pclean, noise] = ime.denoise_matrix(Praw, M);
beam.denoised_spectra = Pclean;
beam.noise_level = noise;
new_beam = beam;
end
