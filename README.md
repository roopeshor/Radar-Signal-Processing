# ST radar
ST Radar wind profile estimation algorithms in NEWS+Z directions.

## Folder structure
The `run.m` is entry file. All functions to a particular class of algorithm (method) is put in a folder with "+" sign before it:

**Directory structure**:

```
├── run.m                         <-- entry file
│
│                               ┐
├── +mccf                       │
│   ├── compute_moments.m       │
│   └── compute_spectra.m       │
├── +simple                     │
│   ├── compute_moments.m       ├─── Methods
│   ├── compute_spectra.m       │
│   ├── denoise_beam.m          │
│   └── HS_noise_estimate.m     │
│                               ┘
│
│                               ┐
├── @Observation                │
│   └── Observation.m           │
├── @RadarData                  │
│   └── RadarData.m             │
└── +utils                      │
    ├── add_reference_data.m    ├─── Utility files
    ├── compute_dbs_factor.m    │
    ├── compute_height_ranges.m │
    ├── compute_max_velocity.m  │
    ├── get_beam_direction.m    │
    └── read_raw_file.m         │
                                ┘
```

So that usage become:
```matlab
% run.m
obs = Observation(filepath);
obs = mccf.compute_all_spectra(obs);
obs = mccf.compute_all_moments(obs);
```


## Reading an Observation
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
```m
obs = {
	north           : [1×1 RadarData]   %
	east            : [1×1 RadarData]   %
	west            : [1×1 RadarData]   % individual beam data
	south           : [1×1 RadarData]   %
	vertical        : [1×1 RadarData]   %

	observation_name: "EXP_DBS_CH4_29Jul2026_16_16_17"

	ref_height      : [94×1 double]     %
	ref_U           : [94×1 double]     % Reference UVW and height
	ref_V           : [94×1 double]     %
	ref_W           : [94×1 double]     %

	DBS_Factor_H    : 2.1054            % computed Doppler Beam Swing parameters
	DBS_Factor_V    : 0.7312            %
}
```

So in the code you can directly use each thing:

```matlab
N = obs.north;
disp(N.ipp_us);
```

Each beam (north, east, ... ) is a another object of class `RadarData`. It has following properties:
(See [@RadarData/RadarData.m](@RadarData/RadarData.m))
```m
N = {
    m_sMagicNumber              : 369
    m_sNumOfRangeBins           : 94
    % Open @RadarData/RadarData.m file to see 50 other fields.

    BeamData                    : [94×1024 double] % raw time series beam data

    ipp_us                      : 161.2903 % alias to m_fIntrPulsePeriod_us
    n_coh                       : 100      % alias to m_sNumOfCohIntegrations
    start_height                : 3150     % alias to m_fWindow1StartHeight
    end_height                  : 20000    % alias to m_fWindow1EndHeight
    direction                   : "north"
    spectra                     : [94×1024 double] % to be filled by spectra computer
    denoised_spectra            : [94×1024 double] %

	% computed moments, to be filled by external function
    M0                          : [94×1 double]
    M1                          : [94×1 double]
    M2                          : [94×1 double]


    filepath                    : "Data/EXP_DBS_CH4_29Jul2026_16_16_17.raw"

	% reference data obtained from other files
    ref_height                  : [94×1 double]
    ref_M0                      : [94×1 double]
    ref_M1                      : [94×1 double]
    ref_M2                      : [94×1 double]
    ref_SNR                     : [94×1 double]
    ref_noise_level             : [94×1 double]
}
	% just some container to store other things given by algorithm
    algorithm_parameters        : struct
```

## File path convention
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

## Function convention
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


### Batch Operations
Some operations has to be done on multiple things. Eg: same moments computer can be used for all 5 beams:
```matlab
obs.north = simple.compute_moments(obs.north)
obs.south = simple.compute_moments(obs.south)
obs.east = simple.compute_moments(obs.east)
obs.west = simple.compute_moments(obs.west)
obs.vertical = simple.compute_moments(obs.vertical)
```

In such cases one has to write 5 similar statements in the runner file. Which is boring, when you have to do same thing for 3 more functions.
Instead you _can_ create another function and pass the `Observation` itself and use a loop to do it:

```matlab
function new_obs = compute_all_moments(obs)
%compute_all_moments computes moment of all beams in the observation
arguments (Input)
	obs Observation
end
arguments (Output)
	new_obs Observation
end
new_obs = obs;
directions = ["north", "east", "west", "south", "vertical"];

for dir = directions
	new_obs.(dir) = simple.compute_moments(obs.(dir));
end
end

obs = mccf.compute_all_moments(obs)

```


## Editorconfig
Different editors use different styles to format things.. (tabs/space for indendation, `LF`/`CRLF` for line endings).
This might produce large diffs when using Git.
To avoid that install [EditorConfig](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig) and [MATLAB](https://marketplace.visualstudio.com/items?itemName=MathWorks.language-matlab) extensions from vscode, and format with it before committing the code.
