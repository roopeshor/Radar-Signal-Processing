# ST radar
Reads ST Radar raw files and displays wind speeds in 5 directions (NEWS+Z).
Implemented in MATLAB.
While running, each script assume that a `Data` folder is sitting just next to it:
```
├── run.m
├── Data
│   ├── Mode_1
│   │   ├── *.raw
```

## Running Matlab
run `run.m` (entry point).


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
