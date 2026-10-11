function noise_level = HS_noise_estimate(spectra, M)
    [numRangeBins, N] = size(spectra);

    noise_level = zeros(numRangeBins, 1);

    if M < 1
        M = 1;
    end

    for r = 1:numRangeBins
        A = sort(spectra(r, :), 'ascend');
        n = (1:N);
        Pn = cumsum(A) ./ n;
        secondMoment = cumsum(A.^2) ./ n;
        Qn = secondMoment - Pn.^2;
        Qn(Qn <= 0) = NaN;
        Rn = (Pn.^2) ./ (M .* Qn);
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
