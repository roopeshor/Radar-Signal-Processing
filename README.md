# ST radar
Reads ST Radar raw files and displays wind speeds in 5 directions (NEWS+Z).
Implemented in MATLAB.

## Folder structure
The `run.m` is entry file. All functions to a particular class of algorithm (method) is put in a folder with "+" sign before it:

**Directory structure**:

```
├── run.m                         <-- entry file
│
│
├── +mccf
│   ├── compute_moments.m       |
│   └── compute_spectra.m       |
├── +simple                     |
│   ├── compute_moments.m       | <-- Methods
│   ├── compute_spectra.m       |
│   ├── denoise_beam.m          |
│   └── HS_noise_estimate.m.m   |
│
│
│
├── @Observation                |
│   └── Observation.m           |
├── @RadarData                  |
│   └── RadarData.m             |
└── +utils                      |
    ├── add_reference_data.m    | <-- Utility files
    ├── compute_dbs_factor.m    |
    ├── compute_height_ranges.m |
    ├── compute_max_velocity.m  |
    ├── get_beam_direction.m    |
    └── read_raw_file.m         |
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

the `obs` is now act like a `struct`  and has following things in it (see [@Observation/Observation.m](@Observation/Observation.m)):
```
obs = {
	north           : [1×1 RadarData]                 //
	east            : [1×1 RadarData]                 //
	west            : [1×1 RadarData]                 // individual beam data
	south           : [1×1 RadarData]                 //
	vertical        : [1×1 RadarData]                 //

	observation_name: "EXP_DBS_CH4_01Jun2025_18_04_28"

	ref_height      : [94×1 double]                  //
	ref_U           : [94×1 double]                  // Reference UVW and height
	ref_V           : [94×1 double]                  //
	ref_W           : [94×1 double]                  //

	DBS_Factor_H    : 2.1054             // computed Doppler Beam Swing parameters
	DBS_Factor_V    : 0.7312             //
}
```

So in the code you can directly use each thing:

```matlab
N = obs.north;
disp(N);
```

Each beam (north, east, ... ) is a another object of class `RadarData`. It has following properties:
(See [@RadarData/RadarData.m](@RadarData/RadarData.m))
```
N = {
    m_sMagicNumber              : 369
    m_sNumOfRangeBins           : 94
    // See @RadarData/RadarData.m file to find 50 other fields.

    BeamData                    : [94×1024 double] // raw time series beam data
    ipp_us                      : 161.2903 // alias to m_fIntrPulsePeriod_us
    n_coh                       : 100      // alias to m_sNumOfCohIntegrations
    start_height                : 3150     // alias to m_fWindow1StartHeight
    end_height                  : 20000    // alias to m_fWindow1EndHeight
    direction                   : "north"
    spectra                     : [0×1024 double] // to be filled by other functions
    denoised_spectra            : [0×1024 double] // to be filled by other functions

	// computed moments, to be filled by external function
    M0                          : [94×1 double]
    M1                          : [94×1 double]
    M2                          : [94×1 double]


    filepath                    : "Data/Mode_2/EXP_DBS_CH4_01Jun2025_18_04_28.raw"

	// reference data obtained from other files
    ref_height                  : [94×1 double]
    ref_M0                      : [94×1 double]
    ref_M1                      : [94×1 double]
    ref_M2                      : [94×1 double]
    ref_SNR                     : [94×1 double]
    ref_noise_level             : [94×1 double]
}
	// just some container to store other things given by algorithm
    algorithm_parameters        : struct
```



## File path convention
To have interoperability with multiple people and operating systems use matlab's `fullfile` function.

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

## Editorconfig
Different editors use different styles to format things.. (tabs/space for indendation, `LF`/`CRLF` for line endings).
This might produce large diffs when using Git.
To avoid that install [EditorConfig](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig) and [MATLAB](https://marketplace.visualstudio.com/items?itemName=MathWorks.language-matlab) extensions from vscode, and format with it before committing the code.
