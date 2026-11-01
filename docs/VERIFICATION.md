# Verification status

MATLAB execution is pending. On 1 November 2026 the installed R2024b application on the development Mac failed before running project code, with `MessageCatalogIncorrectRoot`. Its application resource directory is absent. Expected results are not labelled as MATLAB test passes.

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

The automated workflow must pass on the published commit before this project is described as MATLAB-verified.

## Reference calculation completed

`python3 tools/reference_check.py` executed successfully on 1 November 2026 using Python and NumPy. Its output is saved in `python_reference.json`. Five groups of checks passed: circular geometry, visibility limits, packet-contact boundaries, 10 s versus 2 s access detection, and transmission containment. This validates a separate calculation of the core mathematics; it is **not** execution of the MATLAB files, MATLAB plots, `ode45` test or Monte Carlo implementation.

The reference found 11 Belfast windows for the one-plane case and 12 for the two-plane case, with four Singapore windows in each. These are synthetic scenario results, not guarantees for an operational constellation. The distant target's median delivered summary latency was about 68 minutes despite a 96.54-minute orbital period: contact geometry dominates this example.
