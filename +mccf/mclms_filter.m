function Y_r = mclms_filter(X_r, X_r_prime, mclms_len)
N2 = length(X_r);
% Normalized step size u
u = 1 / sum(abs(X_r).^2);
% Initial filter weights W1 = 0
W = zeros(1, mclms_len);

% Pass 1: Adaptive coefficient training
for j = 1:N2
	if j < mclms_len
		X_vec = [zeros(1, mclms_len - j), X_r(1:j)];
	else
		X_vec = X_r(j - mclms_len + 1 : j);
	end
	Y = W * X_vec.';
	e_j = X_r_prime(j) - Y;
	W = 0.98 * W + u * e_j * conj(X_vec);          % Weight update
end

% Pass 2: Re-filtering with updated weights W2 = W1'
W2 = W;
Y_r = zeros(1, N2);
for j = 1:N2
	if j < mclms_len
		X_vec = [zeros(1, mclms_len - j), X_r(1:j)];
	else
		X_vec = X_r(j - mclms_len + 1 : j);
	end
	Y_r(j) = W2 * X_vec.';
end
end
