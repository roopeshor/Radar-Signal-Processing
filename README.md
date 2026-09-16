# ST Radar Wind Profile Estimation Framework

Atmospheric ST (Stratosphere-Troposphere) Radar signal processing and wind profile estimation framework for 5-beam Doppler Beam Swinging (DBS) observations (North, East, South, West, Vertical).

## Directory Architecture

Method modules are organized into package directories prefixed with `+`. Data objects and utility functions provide a standardized abstraction layer.

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
│   ├── add_reference_data.m           │ Attaches reference .mmts and .uvw ground-truth files
│   ├── compute_height_ranges.m        │ Altitude range bin generator
│   ├── compute_max_freq.m             │ Nyquist unambiguous Doppler frequency calculator
│   ├── compute_radial_velocity.m      │ 3D wind vector line-of-sight projection onto beam
│   ├── compute_velocity_axis.m        │ 1D Doppler velocity axis (m/s) generator
│   ├── create_synthetic_observation.m | Synthesizes artificial 5-beam Observation objects (Zrnic method)
│   ├── create_synthetic_beamheader.m  | Synthesizes artificial beam header
│   ├── fill_moments.m                 │ Batch moment function applier for Observation
│   ├── fill_spectras.m                │ Batch spectra function applier for Observation
│   ├── read_raw_file.m                │ Binary .raw radar file parser
│   ├── synthesize_iq_data.m           │ synthesizes IQ data from radial velocity
│   └── write_raw_file.m               │ Binary .raw radar file serializer

├── stacked_spectrogram.m          <-- Stacked doppler spectrum Plotter
├── @Observation                   <-- Value class representing a 5-beam observation dataset
├── @RadarData                     <-- Subclass of BeamHeader holding raw IQ cubes & post-processing fields
└── @BeamHeader                    <-- Base class for 52 radar binary header fields
└── @Data                          <-- Utility conversion stuffs
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
