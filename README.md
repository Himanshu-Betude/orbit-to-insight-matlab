# Orbit to Insight

**A MATLAB study of satellite access, constellation layout and time to usable information.**

[![MATLAB verification](https://github.com/Himanshu-Betude/orbit-to-insight-matlab/actions/workflows/matlab.yml/badge.svg)](https://github.com/Himanshu-Betude/orbit-to-insight-matlab/actions/workflows/matlab.yml)
[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=Himanshu-Betude/orbit-to-insight-matlab&file=run_study.m)

Four satellites can be evenly spaced in an orbit without providing evenly spaced observations of a ground target. An observation also has to wait for a usable downlink. This project connects those two problems in one reproducible model.

Project owner: **Himanshu Betude**, Aerospace Engineering, Queen's University Belfast.

## What it does

- Compares four spacecraft in one orbital plane with four spacecraft in two planes.
- Calculates target access from a nadir sensor cone and ground contacts from an elevation mask.
- Uses those calculated contacts to compare raw-data delivery with onboard summary delivery.
- Runs 200 seeded trials with changes in processing time and net downlink rate.
- Checks orbital motion against numerical integration and repeats access analysis at finer time steps.
- Exports figures, CSV tables, configuration and run metadata.

This is an orbital and communications scheduling model. It does not implement an image-processing algorithm or simulate a complete spacecraft bus.

## Run

Use MATLAB R2024b. The code uses base MATLAB; Aerospace, Satellite Communications and Statistics toolboxes are not required. Other releases have not been checked.

Open this repository as MATLAB's current folder, then run:

```matlab
results = runtests('tests');
assertSuccess(results);
study = run_study;
animate_orbits  % optional 3D animation; rotate with the mouse
```

`run_study` writes to `results/`. To preserve a run, specify another output folder:

```matlab
study = run_study(fullfile(pwd,'my_run'));
```

Change the mission assumptions in [`+mission/defaultConfig.m`](+mission/defaultConfig.m). There is no API key, live tracking feed or external data download.

## Experiment

| Input | Default |
|---|---|
| Orbit | Circular, 600 km above a 6,371 km sphere |
| Inclination | 55 degrees |
| Spacecraft | Four in both comparison cases |
| Layout 1 | One plane; phases 0, 90, 180, 270 degrees |
| Layout 2 | Two planes at RAAN 0 and 90 degrees; phases 0/180 and 90/270 degrees |
| Targets | Belfast and Singapore, illustrative point locations |
| Ground station | Belfast; minimum elevation 10 degrees |
| Sensor | Nadir pointing; 80-degree full cone |
| Horizon | 24 hours; 10-second detection samples, repeated at 2 seconds |
| Raw product | 180 MB, no onboard reduction delay |
| Summary product | 2 MB, 45 seconds of onboard processing |
| Downlink | 6 Mbit/s net rate; decimal MB |
| Ground processing | 15 seconds for either policy |
| Delivery target | Within 20 minutes of capture |
| Sensitivity | 200 trials; rate 3–9 Mbit/s, processing 15–600 seconds; seed 307 |

The layout comparison changes both orbital plane allocation and phase distribution. It is a comparison of two specified designs, not an optimisation or proof that one plane count is universally better.

## Read the outputs

| File | Meaning |
|---|---|
| `overview.png` | Orbits, target access, delivery latency and uncertainty trials |
| `ground_tracks.png` | Longitude/latitude tracks over two orbits |
| `comparison.csv` | Access duration, access gaps and timely-delivery fraction by layout and target |
| `events_layout_*.csv` | Each modelled observation and its raw/summary delivery times |
| `access_layout_*_target_*.csv` | Merged access start/end times in seconds; no header |
| `sensitivity.csv` | Every uncertainty trial, including assumptions and delivery outcomes |
| `convergence.csv` | Differences between 10-second and 2-second access detection |
| `study.mat` | Configuration, contacts, events and outputs for further work |
| `run_metadata.json` | MATLAB version, generation time and model settings |

`Inf` means that the packet did not fit any remaining contact in the modelled horizon. It does **not** mean the packet would never arrive. `NaN` means that a statistic cannot be calculated, for example an internal access gap with fewer than two windows. Delivery medians include delivered events only; timely-delivery fractions include every modelled observation.

## Scope and assumptions

The Earth is spherical with constant rotation; the orbit is circular and unperturbed. Initial Earth rotation is an explicit zero-angle convention, not a UTC-to-Earth-orientation calculation. This is not a prediction for an operational satellite or a TLE propagator.

Access boundaries are refined by bisection to 1 ms after a sign change is detected. A pass entirely between samples can be missed, which is why the study also runs at a finer sampling interval. The numerical boundary tolerance is not physical accuracy.

Each observation is an **independent event**: it competes with no other observation for onboard processing, storage, transmitter time or the ground antenna. Whole packets must fit in one contact; there is no partial transfer across passes. This deliberately isolates the effect of geometry and waiting for contact. The sensitivity ranges are illustrative, not measured uncertainty or operational reliability estimates.

The summary contains less information than the raw product. Its usefulness and the validity of the assumed processing time are not evaluated. No illumination, cloud, resolution, power, attitude slew, radio link budget, packet loss, intersatellite relay or collision-avoidance model is included.

## Verification and project notes

See [`docs/VERIFICATION.md`](docs/VERIFICATION.md) for what has actually run, and [`docs/METHOD.md`](docs/METHOD.md) for the equations and a short explanation you can use in an interview. The GitHub workflow runs the test suite and regenerates the study; use its status rather than assuming a test passed because its source exists.

This is an original portfolio extension of an orbital reasoning exercise, developed with AI coding assistance. All mission scenarios and uncertainty distributions in this repository are synthetic. No employer questionnaire, recruitment answers, proprietary mission requirements or personal account credentials are included.

## References

- [NASA: Gravity and Mechanics](https://science.nasa.gov/learn/basics-of-space-flight/chapter3-3/) — orbital mechanics background.
- [NASA/JPL: two-body propagation](https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/C/cspice/prop2b_c.html) — two-body model and circular-motion reference case. This project does not use SPICE code.
- [MathWorks: ode45](https://www.mathworks.com/help/matlab/ref/ode45.html) — numerical integrator used for the independent MATLAB dynamics test.
- [MathWorks: MATLAB in GitHub Actions](https://github.com/matlab-actions/setup-matlab) — automated MATLAB setup. Public repositories are eligible for automatic licensing through the MATLAB run actions; private repositories need their own licensing configuration.
