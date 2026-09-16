# ST Radar Wind Profile Estimation Framework

Atmospheric ST (Stratosphere-Troposphere) Radar signal processing and wind profile estimation framework for 5-beam Doppler Beam Swinging (DBS) observations (North, East, South, West, Vertical).

## Directory Architecture

Method modules are organized into package directories prefixed with `+`. Data objects and utility functions provide a standardized abstraction layer.

```
├── run_obs_data.m                <-- Main experimental data processing script
├── run_ime.m                     <-- Synthetic observation processing script
│
├── +imeB                         <-- Modularized IME algorithm package
│   ├── compute_spectra.m         │   Power spectrum calculation (Hanning window + incoherent averaging)
│   ├── remove_dc.m               │   Zero-Doppler ground clutter removal by linear interpolation
│   ├── remove_dc_from_beams.m    │   Batch ground clutter remover across all Observation beams
│   ├── HS_noise_estimate.m       │   Hildebrand-Sekhon noise floor estimation
│   ├── denoiser.m                │   Full spectral denoiser (DC removal + smoothing + HS noise subtraction)
│   ├── denoise_all_beams.m       │   Batch denoiser across all Observation beams
│   ├── adaptive_peak_selection.m │   Adaptive Doppler window prospective candidate peak selector (Step B)
│   ├── profile_tracer.m          │   Dynamic programming velocity profile tracer across range bins (Step C)
│   ├── compute_moments.m         │   Full IME moment calculator for RadarData (hot-swappable)
│   └── compute_uvw.m             │   End-to-end DBS wind vector (U, V, W) retrieval endpoint
│
├── +st                           <-- Reference-matched ST radar moment estimator package
│   ├── compute_spectra.m         │   Time-domain coherent accumulation + Doppler FFT
│   └── compute_moments.m         │   Clutter notch + HS noise + 3-point parabolic peak interpolation
│
├── +mccf                         <-- Mutual Cross-Correlation Function package
│   ├── compute_spectra.m         │   Frequency-domain DC masking + mutual cross-correlation + MCLMS
│   └── compute_moments.m         │   Cost-function-guided peak tracking (Power vs. Velocity Jump penalty)
│
├── +simple                       <-- Baseline Doppler processing package
│   ├── compute_spectra.m         │   Baseline time-domain DC subtraction + Doppler FFT
│   ├── compute_moments.m         │   Standard Woodman peak-expand moment estimator
│   ├── HS_denoise_beam.m         │   Single beam Hildebrand-Sekhon noise floor subtraction
│   ├── HS_denoise_all_beams.m    │   Batch beam Hildebrand-Sekhon noise floor subtraction
│   └── HS_noise_estimate.m       │   Chi-squared Hildebrand-Sekhon noise floor estimation
│
├── +utils                        <-- Shared utility functions
│   ├── add_reference_data.m      │   Attaches reference .mmts and .uvw ground-truth files
│   ├── compute_height_ranges.m   │   Altitude range bin generator
│   ├── compute_max_freq.m        │   Nyquist unambiguous Doppler frequency calculator
│   ├── compute_radial_velocity.m │   3D wind vector line-of-sight projection onto beam
│   ├── compute_velocity_axis.m   │   1D Doppler velocity axis (m/s) generator
│   ├── create_synthetic_observation.m Synthesizes artificial 5-beam Observation objects (Zrnic method)
│   ├── fill_moments.m            │   Batch moment function applier for Observation
│   ├── fill_spectras.m           │   Batch spectra function applier for Observation
│   ├── read_raw_file.m           │   Binary .raw radar file parser
│   └── write_raw_file.m          │   Binary .raw radar file serializer
│
├── @Observation                  <-- Value class representing a 5-beam observation dataset
├── @RadarData                    <-- Subclass of BeamHeader holding raw IQ cubes & post-processing fields
└── @BeamHeader                   <-- Base class for 52 radar binary header fields
```

## Standard Execution Workflow

### 1. Reading an Observation
Instantiate an `Observation` object using the base filename path. The parser automatically loads the binary raw data (`.raw`) and optional reference files (`.mmts`, `.uvw`):

```matlab
filepath = fullfile("Data", "EXP_DBS_CH4_29Jul2026_19_17_20");
obs = Observation(filepath);
```

### 2. Processing Pipeline via Hot-Swappable Endpoints

Methods (`+imeB`, `@mccf`, `@st`, `@simple`) export standardized function handles for `compute_spectra` and `compute_moments`:

```matlab
% Example: IME Method (+imeB)
obs = utils.fill_spectras(obs, @imeB.compute_spectra);
obs = imeB.remove_dc_from_beams(obs);
obs = imeB.denoise_all_beams(obs);
obs = utils.fill_moments(obs, @imeB.compute_moments);

% Example: MCCF Method (+mccf)
obs = utils.fill_spectras(obs, @mccf.compute_spectra);
obs = simple.HS_denoise_all_beams(obs);
obs = utils.fill_moments(obs, @mccf.compute_moments);
```

### 3. Extracting Wind Profiles (DBS Equations)

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
