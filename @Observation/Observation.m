classdef Observation
	% Observation  Value class representing all given data in observation.
	%
	% Each beam headers are present in north, east, west, south and vertical properties
	% Reference data "ref_..." are obtained from uvw file.
	% The height data is obtained from the uvw file.
	% Moments references are put in each beam, see RadarData class.
	% To use this class, instantiate the class with base name of the observation files
	% all raw, uvw, mmts will be automatically found and data will be extracted
	properties
		north RadarData
		east RadarData
		west RadarData
		south RadarData
		vertical RadarData

		raw_filepath string

		ref_height (1, :) double % from uvw file
		ref_U (1, :) double
		ref_V (1, :) double
		ref_W (1, :) double

		% computed props
		U (1, :) double
		V (1, :) double
		W (1, :) double

		heights (1, :) double % computed heights from @utils.compute_height_bins
		velocities (1, :) double % computed velocities from @utils.compute_velocity_bins

		% DBS factors [m]: scaling factor to convert Doppler frequencies (Hz) into wind velocities (m/s).
		% Horizontal DBS factor = λ/(2sin(oz))
		DBS_Factor_H (1, 1) double
		% Vertical DBS factor = λ/2
		DBS_Factor (1, 1) double

		% assumes following parameters are same for all 5 beams
		f_max (1, 1) double % maximum frequency deviation in the doppler spectrum
		v_max (1, 1) double % maximum velocity in the doppler spectrum
		start_height (1, 1) double % start height from one of the beams
		end_height (1, 1) double % end height from one of the beams
		nRangeBins (1, 1) double % number of range bins
		ipp_us (1, 1) double % Intr Pulse Period in microseconds
		in_coh (1, 1) double % Incoherent integrations
		n_coh (1, 1) double % coherent integrations
		nFFT (1, 1) double % number of FFT bins
	end
end
