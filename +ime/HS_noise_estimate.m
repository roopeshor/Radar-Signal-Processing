function noise_level = HS_noise_estimate(spectra, in_coh)
	arguments(Input)
		spectra (:, 1024) double
		in_coh (1,1) double % incoherent integrations
	end
	arguments(Output)
		noise_level (1, :) double
	end
    [numRangeBins, N] = size(spectra);

    noise_level = zeros(1, numRangeBins);

    if in_coh < 1
        in_coh = 1;
    end

    for r = 1:numRangeBins
        A = sort(spectra(r, :), 'ascend');
        n = (1:N);
        Pn = cumsum(A) ./ n;
        secondMoment = cumsum(A.^2) ./ n;
        Qn = secondMoment - Pn.^2;
        Qn(Qn <= 0) = NaN;
        Rn = (Pn.^2) ./ (in_coh .* Qn);
        valid = find(Rn > 1);
        if isempty(valid)
            % No statistically valid noise region.
            % Conservative fallback: lowest few spectral points.
            k = max(1, round(0.1*N));
        else
            k = max(valid);
        end
        noise_level(r) = Pn(k);
    end
end
