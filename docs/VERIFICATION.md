# Verification status

**MATLAB verification passed on 1 November 2026: 13 passed, 0 failed, 0 incomplete.** The full study also completed and generated figures, CSV tables and run metadata.

- MATLAB R2024b on a GitHub-hosted Ubuntu 22.04 runner.
- Verified source: `13cf321ae615c4dd598ff7434438f48701f4e394`.
- [Execution log and downloadable artifacts](https://github.com/Himanshu-Betude/orbit-to-insight-matlab/actions/runs/41353362334).
- [Selected generated results](example_results), including run/source provenance.

The installed MATLAB application on the development Mac could not start because its resource directory is missing; no local MATLAB execution is claimed. The initial cloud run found a missing test-path setup, which was corrected before this successful run. Interactive animation has not been manually checked; the study's static 3D plots were generated in MATLAB.

The repository contains 13 MATLAB tests covering:

1. Circular radius, orbital energy and angular momentum.
2. Analytic motion against independent `ode45` integration over two orbits.
3. Earth-fixed frame rotation.
4. Overhead and occulted target geometry.
5. The spherical horizon limit.
6. An unreachable high-latitude target.
7. Access boundary refinement, continuous access and no-access cases.
8. Window union, gap metrics and horizon edges.
9. Whole-packet capacity and exact end-of-contact boundaries.
10. A case in which contact waiting dominates processing time.
11. End-to-end events staying inside their actual downlink contacts.
12. Access sampling refined from 10 to 2 seconds.
13. Repeatable seeded sensitivity trials.

The 10-second and 2-second access scans found identical window counts. Total access-duration differences were at most 0.00135 seconds for these four layout/target combinations. This checks numerical resolution for this scenario; it does not establish physical accuracy or rule out missed short passes in other configurations.

## Reference calculation completed

`python3 tools/reference_check.py` executed successfully on 1 November 2026 using Python and NumPy. Its output is saved in `python_reference.json`. Five groups of checks passed: circular geometry, visibility limits, packet-contact boundaries, 10 s versus 2 s access detection, and transmission containment. This validates a separate calculation of the core mathematics; it is **not** execution of the MATLAB files, MATLAB plots, `ode45` test or Monte Carlo implementation.

The reference found 11 Belfast windows for the one-plane case and 12 for the two-plane case, with four Singapore windows in each. These are synthetic scenario results, not guarantees for an operational constellation. The distant target's median delivered summary latency was about 68 minutes despite a 96.54-minute orbital period: contact geometry dominates this example.
