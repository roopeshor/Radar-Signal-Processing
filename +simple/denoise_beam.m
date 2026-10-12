function beam = denoise_beam(beam)
% Denoises a single RadarData beam by subtracting Hildebrand-Sekhon noise.

arguments (Input)
	beam RadarData
end
arguments (Output)
	beam RadarData
end

if isempty(beam.denoised_spectra)
	spec = beam.spectra;
else
	spec = beam.denoised_spectra;
end

noise_level = beam.noise_level;
if isempty(noise_level)
	noise_level = simple.HS_noise_estimate(beam);
end

denoised_spectra = spec - noise_level';
denoised_spectra(denoised_spectra < 0) = 0;

beam.noise_level = noise_level;
beam.denoised_spectra = denoised_spectra;
end
