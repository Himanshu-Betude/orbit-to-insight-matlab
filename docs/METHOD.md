# Model and explanation

## The question

How do orbital layout and data handling affect the time between seeing a location and delivering useful information to the ground?

The simulation follows this chain:

```text
Orbit and initial phase
        ↓
Position relative to a rotating Earth
        ↓
Target inside the sensor cone → observation at the pass midpoint
        ↓
Raw product OR processing into a smaller summary
        ↓
Wait for the observing satellite's next usable ground contact
        ↓
Fit the entire packet inside that contact
        ↓
Ground processing → usable result
```

## Orbital state

Use kilometres and seconds. For radius `a = Earth radius + altitude`:

`n = sqrt(mu / a^3)` and `period = 2*pi/n`.

At time `t`, the orbital-plane position is `[a*cos(u); a*sin(u); 0]`, where `u = initial phase + n*t`. Rotate by the inclination and RAAN to obtain inertial coordinates. Rotate those coordinates by the negative Earth rotation angle to obtain Earth-fixed coordinates. The velocity is the time derivative of the inertial position.

All four spacecraft share altitude and inclination. The experiment changes their planes and phases. The numerical test independently integrates `r'' = -mu*r/|r|^3` using `ode45`, then compares that trajectory with the analytic one. Energy and angular-momentum tests check conservation in the two-body model.

## Access

For ground position `g`, spacecraft position `r`, and local radial unit vector `g/|g|`:

`elevation = asin(dot(r-g, g/|g|) / |r-g|)`.

A downlink is available when this elevation exceeds the configured mask. Imaging additionally requires the angle between the nadir direction `-r` and the vector `g-r` to be at most half the full field of view. A line-of-sight check excludes the far side of Earth.

Sample the signed constraint margin. Refine each detected transition with bisection. Merge overlapping target windows from different spacecraft before calculating constellation access statistics.

**Period divided by satellite count is not target revisit.** The target rotates with Earth, its latitude matters, and the sensor has a finite field of view. Measure revisit from the target's actual access windows.

Report separately:

- Internal gap: one access ends to the next access starting.
- Start spacing: successive observed pass starts, excluding a start clipped at the simulation epoch.
- Maximum observed gap: also includes the beginning/end of the finite horizon. Edge gaps are incomplete and do not establish a global worst-case revisit.

## Delivery

Transmission duration is `8 * size_MB / net_rate_Mbps`.

For each contact, try starting at the later of the packet-ready time and contact opening. Accept the first contact that can contain the entire transmission. Add ground processing time to obtain usable-information time. Latency is measured from capture, not from the simulation epoch.

Raw and summary delivery are counterfactual alternatives for the same event. Events themselves are evaluated independently. This is not a traffic queue simulation, and the outputs must not be called a fleet throughput guarantee.

## Sensitivity

Each trial draws one rate and one onboard-processing delay and applies that pair across the same observation events. The seed is fixed so rerunning in the same MATLAB environment reproduces the draws. Independent uniform distributions explore a chosen range; they are not calibrated hardware statistics.

## Explain it in an interview

“I developed a MATLAB portfolio study that connects orbital access to data delivery. It compares two four-satellite layouts, calculates when they can observe two targets, and checks whether a raw packet or a smaller processed product can fit into a ground-station contact. I added numerical dynamics checks, finer-step access checks and seeded sensitivity trials. The main modelling lesson is that faster onboard processing may not reduce delivery time if both products still have to wait for the same contact.”

Review the code and generated results before using this wording. Be ready to explain the independent-event assumption, spherical Earth, full versus half sensor angle, the meaning of `Inf`, and why reduced data volume does not guarantee equivalent information quality.

Useful terms: **RAAN** is orbital-plane orientation around Earth's axis; **inclination** is the tilt of that plane; **ground track** is the path of the subsatellite point; **access window** is an interval when geometric conditions hold; **latency** is elapsed time from capture to usable output; **Monte Carlo** repeats the calculation with sampled inputs; **convergence** checks how results change when numerical resolution is refined.
