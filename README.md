# ST radar
Reads ST Radar raw files and displays wind speeds in 5 directions (NEWS+Z).
Implemented in MATLAB.

## Folder structure
The `run.m` is entry file. All functions to a particular class of algorithm (method) is put in a folder with "+" sign before it:
```
├── run.m                  <--- entry file
│
├── +mccf
│   ├── compute_mccf_moments.m             |
│   └── compute_mccf_spectra.m             |
├── +simple                                |
│   ├── compute_beam_moments.m             | <-- Methods
│   ├── compute_simple_spectra.m           |
│   ├── denoise_beam.m                     |
│   └── hildebrand_sekhon_noise_estimate.m |
│
│
├── @Observation                   |
│   └── Observation.m              |
├── @RadarData                     |
│   └── RadarData.m                |
└── +utils                         |
    ├── add_reference_data.m       | <-- Utility files
    ├── compute_dbs_factor.m       |
    ├── compute_height_ranges.m    |
    ├── compute_max_velocity.m     |
    ├── get_beam_direction.m       |
    └── read_raw_file.m            |

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
