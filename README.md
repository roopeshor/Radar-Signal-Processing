# ST radar
ST Radar wind profile estimation algorithms in NEWS+Z directions.

## Folder structure

A group of algorithms related to a method are organized into package directories prefixed with `+` (matlab's convention).

```
├── @Data/Data.m                |
├── @Observation/Observation.m  ├ Data Structures & constants
├── @RadarData/RadarData.m      |
|
├── +ime      |
│   └── ...   |
├── +mccf     |
│   └── ...   |
├── +simple   ├ Methods
│   └── ...   |
├── +st       |
│   └── ...   |
|
├── +synth     <- Related to synthesis of radar data
├── +io        <- File I/O
├── +plt       <- Data plotters
├── +utils     <- Other utilities
|
├── run_xyz.m  <- run scripts
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
obs = getObservation(filepath);
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
obs = getObservation(filepath);
```

### Processing Pipeline via Hot-Swappable Endpoints

Methods (`+ime`, `@mccf`, `@st`, `@simple`) export standardized function handles for `compute_beam_spectra` and `compute_moments`:

```matlab
% Example: IME Method (+ime)
obs = apply_beam_fx(obs, @ime.compute_beam_spectra);
obs = apply_beam_fx(obs, @ime.denoise_beam);
obs = apply_beam_fx(obs, @ime.estimate_params, vel_axis=obs.velocities);
obs = apply_beam_fx(obs, @ime.compute_moments);
obs = utils.compute_uvw(obs);

% Example: MCCF Method (+mccf)
obs = apply_beam_fx(obs, @mccf.compute_beam_spectra);
obs = apply_beam_fx(obs, @simple.denoise_beam);
obs = apply_beam_fx(obs, @mccf.compute_moments);
```

### Extracting Wind Profiles (DBS Equations)

To retrieve zonal ($U$), meridional ($V$), and vertical ($W$) wind velocity profiles from the 5 beam moments:
. Use `utils.compute_uvw` for this
```matlab
N = obs.north; S = obs.south; E = obs.east; W = obs.west; V = obs.vertical;

% Zonal Wind (East-West)
calc_U = -(E.M1 - W.M1) * obs.DBS_Factor_H;

% Meridional Wind (North-South)
calc_V = -(N.M1 - S.M1) * obs.DBS_Factor_H;

% Vertical Wind (W)
c_th = cosd(N.m_fOffZenith);
sum_M1 = E.M1 + W.M1 + N.M1 + S.M1;
calc_W = -obs.DBS_Factor * (c_th * sum_M1 + V.M1) / (4 * c_th^2 + 1);
```

## Synthetic data creation

The synthetic data is created to do batch testing of algorithms with randomized control parameters.
All functions related to synthesis are stored in `+synth` folder
### steps
1. Creating a synthetic Beam header using [create_synthetic_beamheader.m](+synth/create_synthetic_beamheader.m):
	```matlab
	H = synth.create_synthetic_beamheader(...
		altitudeRange="lower", ...
		headerFields=struct("m_sCurrentBeamCnt", 2) ...
	);
	```
	From many of observation it seems that there are just 3 possible set of beam header values and it depeneds on height:
	- set1: 315m to 8100m   (lower)
	- set2: 3150m to 20000m (middle)
	- set2: 6030m to 32000m (upper)

	So the function takes `altitudeRange` parameter (lower/middle/upper) and returns a suitable header. (It actually return a entire `RadarData` class)
	To obtain a beam in particular direction change `m_sCurrentBeamCnt` value, see [beam count mapping](@Data/Data.m#L26) to see what values map to which direction.
	Other parameters can be changed by passing it to `headerFields` struct.
2. Create UVW array:
	```matlab
	[h, u, v, w] = synth.generate_wind_profile( ...
		"start_height", H.start_height, ...
		"end_height", H.end_height ...
		"nRangeBins", H.nRangeBins, ...
	);
	```
	The function also returns a array of height bins (not used usually, but just keeping for future use).
	Many parameters can be passed to this function that alters the final velocity. see [generate_wind_profile](+synth/generate_wind_profile.m) to see all the parameters.
3. Generate observation:
   1. Project uvw onto radial velocity in 5 beam direcitions
   2. convert this velocity to frequency shift
   3. use this frequency shift to create a spectra with gaussian distribution with mean at this frequency and with some arbitrary spread
   4. add ground clutter, DC clutter, bright bands, and IQ noise to spectrum
   5. convert spectrum to time series (with ifft)



## More about architecture
### Function convention
Put all functions related to a particular method (MCCF, MPCF, ...) into a folder.
A method probably would have some specific algorithm for computing spectrum, denoising it, finding moments, etc..
And sometimes algorithms from unrelated methods might produce best results. So for mixing and matching algorithms a common function signature is required for each algorithms.

### Input to function
If it depends on the beam, then beam as a whole should be given to the function.
And if the function expects some custom parameters (say DBS factors, windowing functions, etc), it should be passed as a optional argument.
So a function signature should look like this:

```matlab
function out = some_param_calculator(beam, cfg)
	arguments (Input)
		beam RadarData
		cfg.window function_handle = @hann
		cfg.size double = 5
		...
	end
end

out = some_param_calculator(out.north, window=@hann, size=3)
```
Also optional arguments should have some default value.

Always add `arguments` block to every function to specify the datatype of the inputs and outputs.
This prevents lot of bugs and also gives useful intelllisense/suggestions in code editor.

### Output from function

If function produces some paricular parameters its is advised to put that parameter in the beam's `a_params` struct and return the beam as a whole
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
	...
	new_beam.M0 = M0;
	new_beam.M1 = M1;
	new_beam.M2 = M2;
end

N = compute_moments(out.north);
S = compute_moments(out.south);
E = compute_moments(out.east);
```
For this to work, the beam should have required fields (M0, ref_M0, etc).
If beam doesnt have it, then it can store it in `a_params` parameter in the beam or
if the parameter is something you think important, create new entry for it in [@RadarData/RadarData.m](@RadarData/RadarData.m)

There can be exception to this convention, eg: utility functions that computing a scaling factor.

(MATLAB doesnt have "pass by reference" to modify beam itself, hence modified beam has to be returned).


## Editorconfig
Different editors use different styles to format things.. (tabs/space for indendation, `LF`/`CRLF` for line endings).
This might produce large diffs when using Git.
To avoid that install [EditorConfig](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig) and [MATLAB](https://marketplace.visualstudio.com/items?itemName=MathWorks.language-matlab) extensions from vscode, and format with it before committing the code.
