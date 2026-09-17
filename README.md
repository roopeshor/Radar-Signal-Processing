# ST radar
ST Radar wind profile estimation algorithms in NEWS+Z directions.

## Folder structure

All class of algorithm are organized into package directories prefixed with `+` (matlab's convention). All functions within a algorithm are put in this folder.

```
├── run_ime.m                     <-- IME run script
├── run_obs_data.m                <-- MCCF and simple algorithm tester
├── run_ref_match_test.m          <-- checks if reference M1 can be used to compute uvw
├── run_resynthesized_data.m      <-- checks if synthesizer can generate new observation from uvw of existing
├── run_simulated_data.m          <-- plots output of randomly synthesized raw data
│
├── +ime                          <-- IME algorithm package
│   ├── compute_spectra.m              |
│   ├── remove_dc.m                    |
│   ├── remove_dc_from_beams.m         |
│   ├── HS_noise_estimate.m            |
│   ├── denoiser.m                     |
│   ├── denoise_all_beams.m            |
│   ├── adaptive_peak_selection.m      |
│   ├── profile_tracer.m               |
│   ├── compute_moments.m              |
│   └── compute_uvw.m                  |
│
├── +st                                <-- tried to match ST radar moment estimator
│   ├── compute_spectra.m              │
│   └── compute_moments.m              │   HS noise + 3-point parabolic peak interpolation
│
├── +mccf                              <-- Mutual convolution Cost Function package
│   ├── compute_spectra.m              │
│   └── compute_moments.m              │
│
├── +simple                            <-- Baseline Doppler processing package
│   ├── compute_spectra.m              │
│   ├── compute_moments.m              │
│   ├── HS_denoise_beam.m              │
│   ├── HS_denoise_all_beams.m         │
│   └── HS_noise_estimate.m            │
│
├── +utils                             <-- Shared utility functions
│   ├── add_reference_data.m           │ Attaches reference .mmts and .uvw data to Observation objects
│   ├── compute_height_ranges.m        │ Altitude range bin generator
│   ├── compute_max_freq.m             │ calculates unambiguous Doppler velocity (V_max)
│   ├── compute_radial_velocity.m      │ projects uvw to partiular direction
│   ├── compute_velocity_axis.m        │ Generates Doppler velocity axis (-V_max...+V_max) (m/s)
│   ├── create_synthetic_observation.m | Synthesizes artifical Observation objects
│   ├── create_synthetic_beamheader.m  | Synthesizes beam header
│   ├── fill_moments.m                 │ Batch moment function applier for Observation
│   ├── fill_spectras.m                │ Batch spectra function applier for Observation
│   ├── read_raw_file.m                │ Binary .raw radar file parser
│   ├── synthesize_iq_data.m           │ synthesizes IQ data from radial velocity (Zrnic method)
│   └── write_raw_file.m               │ Binary .raw radar file serializer
│
├── stacked_spectrogram.m          <-- Stacked doppler spectrum plotter
├── generate_wind_profile.m        <-- generates a artifical wind profile using combination of models.
├── @Observation                   <-- Value class representing a 5-beam observation dataset along with other properties
├── @RadarData                     <-- Extension of BeamHeader holding raw IQ data & other fields
├── @BeamHeader                    <-- Base class for 52 radar header fields
├── @Data                          <-- Conversion functions and constants
│
└── Data                           <-- Folder containing actual radar data
```

The data is assumed to be in `Data` folder,

### Data directory
An observation is a collection of all data of a partiular timestamp
If a raw file is present in folder `Data`, then all other derived files are expected to be in the same folder:
```
└── Data
    ├── EXP_DBS_CH4_29Jul2026_16_16_17.raw
    ├── EXP_DBS_CH4_29Jul2026_16_16_17_Beam1_W1_Az_0.00_Oz_0.00.mmts
    ├── EXP_DBS_CH4_29Jul2026_16_16_17_Beam2_W1_Az_90.00_Oz_10.00.mmts
    ├── EXP_DBS_CH4_29Jul2026_16_16_17_Beam3_W1_Az_270.00_Oz_10.00.mmts
    ├── EXP_DBS_CH4_29Jul2026_16_16_17_Beam4_W1_Az_180.00_Oz_10.00.mmts
    ├── EXP_DBS_CH4_29Jul2026_16_16_17_Beam5_W1_Az_0.00_Oz_10.00.mmts
    ├── EXP_DBS_CH4_29Jul2026_16_16_17_W1.uvw
```
All files related to one observation is expected to have a common base name (`EXP_DBS_CH4_29Jul2026_16_16_17` in this example.)
All other files are derived by adding a suitable extension to this base name. The file extension can me modified by changing `@Observation/Observation.m` file.

To read an observation, an object is created from `Observation` class with _path_ of observation passed to it:
```matlab
filepath = fullfile("Data" , "EXP_DBS_CH4_29Jul2026_16_16_17");
obs = Observation(filepath);
```
the `obs` is like a `struct` and has following things in it (see [@Observation/Observation.m](@Observation/Observation.m)):

### File path convention
Windows uses backward slash "\" to separate folders and files in path, while unix (Linux, Mac) uses forward shash "/". To make code work across operating systems use matlab's `fullfile` function.

Example:
Instead of

```m
filepath = "Data\Mode_1\EXP_DBS_CH4_01Jun2025_10_42_31.raw"
```

use:
```m
filepath = fullfile("Data", "Mode_1",  "EXP_DBS_CH4_01Jun2025_10_42_31.raw")
```

Also put the data folder next to the code file (instead of putting it in the desktop or another disk):


## Program flow

### Reading an Observation
Instantiate an `Observation` object using the base filename path. The parser automatically loads the binary raw data (`.raw`) and optional reference files (`.mmts`, `.uvw`):

```matlab
filepath = fullfile("Data", "EXP_DBS_CH4_29Jul2026_19_17_20");
obs = Observation(filepath);
```

### Processing Pipeline via Hot-Swappable Endpoints

Methods (`+ime`, `@mccf`, `@st`, `@simple`) export standardized function handles for `compute_spectra` and `compute_moments`:

```matlab
% Example: IME Method (+ime)
obs = utils.fill_spectras(obs, @ime.compute_spectra);
obs = ime.remove_dc_from_beams(obs);
obs = ime.denoise_all_beams(obs);
obs = utils.fill_moments(obs, @ime.compute_moments);

% Example: MCCF Method (+mccf)
obs = utils.fill_spectras(obs, @mccf.compute_spectra);
obs = simple.HS_denoise_all_beams(obs);
obs = utils.fill_moments(obs, @mccf.compute_moments);
```

### Extracting Wind Profiles (DBS Equations)

To retrieve zonal ($U$), meridional ($V$), and vertical ($W$) wind velocity profiles from the 5 beam moments:

```matlab
N = obs.north; S = obs.south; E = obs.east; W = obs.west; V = obs.vertical;

% Zonal Wind (East-West)
calc_U = -(E.M1 - W.M1) * obs.DBS_Factor_H;

% Meridional Wind (North-South)
calc_V = -(N.M1 - S.M1) * obs.DBS_Factor_H;

% Vertical Wind (W)
c_th = cosd(N.m_fOffZenith);
sum_M1 = E.M1 + W.M1 + N.M1 + S.M1;
calc_W = -obs.DBS_Factor_V * (c_th * sum_M1 + V.M1) / (4 * c_th^2 + 1);
```

## More about architecture
### Function convention
Put all functions related to a particular method (MCCF, MPCF, ...) into a folder.
A method probably would have some specific algorithm for computing spectrum, denoising it, finding moments, etc..
And sometimes algorithms from unrelated methods might produce best results. So for mixing and matching algorithms a common function signature is required for each algorithms.

### Input to function
If it depends on some part of the observation, a beam as a whole _should_ be given to the function.
And if the function expects some other part of the observation or some custom parameters (say DBS factors, windowing functions, etc), it _should_ be passed as a optional argument. So a function signature should look like this:

```matlab
function out = some_param_calculator(beam, options)
	arguments (Input)
		beam RadarData
		options.window function_handle = @hann
		options.size double = 5
		...
	end
	arguments (Output)
        out (:, 1024) double
    end
end

out = some_param_calculator(out.north, window=@hann, size=3)
```

Also optional arguments should have some default value.

_Always_ add `arguments` block to every function to specify the datatype of the inputs and output. This prevents lot of bugs and also gives useful intelllisense/suggestions in code editor.

### Output from function
If a function produces 1 output (a spectra, or denoised spectra) it can be returned as such:

```matlab

function spectra = compute_spectra(beam)
	arguments (Input)
		beam RadarData
	end
	arguments (Output)
        spectra (:, 1024) double
    end
	% do something with beam
	% ....

	spectra = some_result
end

out.spectra = compute_spectra(out.north);
```
Or if it modifies a beam, the output can be directly added to beam itself.
If a function produces 2 or more outputs (Moments, or some other things), The function _should_ copy given beam, add those things to it and return the new beam.
This is to make the syntax more concise. Instead if all 3 moments were returned as an array, then calling the function would become verbose:
```matlab
function [M0, M1, M2] = compute_moments(beam)
...
end
[N_M0, N_M1, N_M2] = compute_moments(obs.north)
[S_M0, S_M1, S_M2] = compute_moments(obs.south)
[E_M0, E_M1, E_M2] = compute_moments(obs.east)
```
This can be avoided if the outputs are packaged into the beam itself:

```matlab

function new_beam = compute_moments(beam)
	new_beam = beam;
	new_beam.M0 = M0;
	new_beam.M1 = M1;
	new_beam.M2 = M2;
end

N = compute_moments(out.north);
S = compute_moments(out.south);
E = compute_moments(out.east);
```

For this to work, the beam should have required fields (M0, ref_M0, etc). If beam doesnt have it, then it can store it in `algorithm_parameters` parameter in the beam or if the parameter is something you think important, create new entry for it in [@RadarData/RadarData.m](@RadarData/RadarData.m)

(MATLAB doesnt have "pass by reference" to modify beam itself, hence modified beam has to be returned).

## Editorconfig
Different editors use different styles to format things.. (tabs/space for indendation, `LF`/`CRLF` for line endings).
This might produce large diffs when using Git.
To avoid that install [EditorConfig](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig) and [MATLAB](https://marketplace.visualstudio.com/items?itemName=MathWorks.language-matlab) extensions from vscode, and format with it before committing the code.
