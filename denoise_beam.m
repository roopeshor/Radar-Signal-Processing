function out_beam = denoise_beam(beam)
	arguments
		beam RadarData
	end

	[~, nfft] = size(beam.spectra);
	noise_level = hildebrand_sekhon_noise_estimate(beam.spectra, beam.m_sNumOfInCohIntegrations);

	% subtract noise level
	noiseLevelPerBin = repmat(noise_level, 1, nfft);
	denoised_spectra = beam.spectra - noiseLevelPerBin;

	% zero the negative
	denoised_spectra(denoised_spectra < 0) = 0;
	out_beam = beam;
	out_beam.denoised_spectra = denoised_spectra;
end
