"""Independent Python check of geometry and packet timing, not a MATLAB run.

Python 3 + NumPy. Writes a labelled reference JSON outside MATLAB results.
"""
from pathlib import Path
import json
import math
import numpy as np

R, A, MU, DAY = 6371.0, 6971.0, 398600.4418, 86164.0905
N = math.sqrt(MU / A**3)
T = 2 * math.pi / N
INC = math.radians(55)
HORIZON = 86400.0
SITES = (("Belfast", 54.60, -5.93), ("Singapore", 1.35, 103.82))
LAYOUTS = (((0, 0), (0, 90), (0, 180), (0, 270)),
           ((0, 0), (0, 180), (90, 90), (90, 270)))


def inertial(raan, phase, times):
    t = np.atleast_1d(times)
    o = math.radians(raan)
    p = np.array([math.cos(o), math.sin(o), 0])
    q = np.cross(np.array([math.sin(o)*math.sin(INC),
                          -math.cos(o)*math.sin(INC), math.cos(INC)]), p)
    u = math.radians(phase) + N*t
    return A*(p[:, None]*np.cos(u) + q[:, None]*np.sin(u))


def fixed(raan, phase, times):
    p = inertial(raan, phase, times)
    theta = 2*np.pi*np.atleast_1d(times)/DAY
    return np.vstack((p[0]*np.cos(theta)+p[1]*np.sin(theta),
                      -p[0]*np.sin(theta)+p[1]*np.cos(theta), p[2]))


def margin(raan, phase, lat, lon, times, imaging):
    lat, lon = np.radians([lat, lon])
    u = np.array([np.cos(lat)*np.cos(lon), np.cos(lat)*np.sin(lon), np.sin(lat)])
    r = fixed(raan, phase, times)
    line = r - R*u[:, None]
    distance = np.linalg.norm(line, axis=0)
    elev = np.degrees(np.arcsin(np.clip(u@line/distance, -1, 1)))
    if not imaging:
        return elev - 10
    off = np.degrees(np.arccos(np.clip(np.sum(line*r, axis=0)/(distance*A), -1, 1)))
    return np.minimum(elev, 40-off)


def windows(fn, step):
    t = np.arange(0, HORIZON+step, step)
    active = fn(t) >= 0
    edges = [0.0] if active[0] else []
    for j in np.flatnonzero(active[:-1] != active[1:]):
        lo, hi = t[j], t[j+1]
        while hi-lo > .001:
            mid = (lo+hi)/2
            if bool(fn(mid)[0] >= 0) == bool(active[j]):
                lo = mid
            else:
                hi = mid
        edges.append((lo+hi)/2)
    if active[-1]:
        edges.append(HORIZON)
    return np.array(edges).reshape(-1, 2)


def merged(w):
    out = []
    for a, b in sorted(w):
        if out and a <= out[-1][1]:
            out[-1][1] = max(out[-1][1], b)
        else:
            out.append([a, b])
    return np.array(out).reshape(-1, 2)


def packet(ready, size, contacts, rate):
    for opening, closing in contacts:
        start = max(ready, opening)
        finish = start+8*size/rate
        if finish <= closing+1e-9:
            return start, finish
    return math.inf, math.inf


def analyse(layout, step):
    accesses = [[], []]
    events = []
    for sat, (raan, phase) in enumerate(layout, 1):
        contacts = windows(lambda t: margin(raan, phase, 54.60, -5.93, t, False), step)
        for target, (_, lat, lon) in enumerate(SITES):
            w = windows(lambda t: margin(raan, phase, lat, lon, t, True), step)
            accesses[target].extend(w.tolist())
            for opening, closing in w:
                capture = (opening+closing)/2
                raw_s, raw_e = packet(capture, 180, contacts, 6)
                sum_s, sum_e = packet(capture+45, 2, contacts, 6)
                if math.isfinite(sum_e):
                    assert any(sum_s >= a-1e-6 and sum_e <= b+1e-6 for a,b in contacts)
                events.append((target, capture, raw_e+15-capture, sum_e+15-capture))
    return [merged(w) for w in accesses], events


def main():
    checks = []
    r = inertial(30, 15, np.linspace(0, 3*T, 1000))
    assert np.max(np.abs(np.linalg.norm(r, axis=0)-A)) < 1e-8
    assert np.max(np.abs(inertial(30, 15, 0)-inertial(30, 15, T))) < 1e-8
    checks.append('Circular radius and period closure')
    assert margin(0, 0, 0, 0, 0, True)[0] > 0
    assert margin(0, 180, 0, 0, 0, True)[0] < 0
    assert margin(0, 0, 85, 0, np.arange(0, 86400, 10), True).max() < 0
    checks.append('Overhead, occultation and high-latitude exclusion')
    assert packet(100,5,[(100,120),(200,240)],2) == (100,120)
    assert packet(100.01,5,[(100,120),(200,240)],2) == (200,220)
    assert math.isinf(packet(0,20,[(0,10),(20,30)],8)[1])
    checks.append('Exact capacity, missed contact and no fragmented transfer')
    rows = []
    for k, layout in enumerate(LAYOUTS, 1):
        w, ev = analyse(layout, 10)
        wf, _ = analyse(layout, 2)
        for q, (name, _, _) in enumerate(SITES):
            assert w[q].shape == wf[q].shape
            assert np.max(np.abs(w[q]-wf[q]), initial=0) < .002
            ee = [e for e in ev if e[0] == q]
            raw = [e[2] for e in ee]
            summary = [e[3] for e in ee]
            finite = [d for d in summary if math.isfinite(d)]
            rows.append(dict(layout=k,target=name,windows=len(w[q]),events=len(ee),
                coverage_min=float(np.sum(w[q][:,1]-w[q][:,0])/60),
                raw_within_20min=sum(x<=1200 for x in raw)/len(ee) if ee else None,
                summary_within_20min=sum(x<=1200 for x in summary)/len(ee) if ee else None,
                median_delivered_latency_min=float(np.median(finite)/60) if finite else None))
    checks.append('Both layouts: 10 s versus 2 s windows agree within 2 ms')
    checks.append('Finite summary transmissions fit the observing spacecraft contacts')
    out = dict(execution='Python reference, NOT MATLAB execution',period_min=T/60,
               checks=checks,results=rows)
    path = Path(__file__).resolve().parents[1]/'docs'/'python_reference.json'
    path.write_text(json.dumps(out,indent=2)+'\n')
    print(json.dumps(out,indent=2))

if __name__ == '__main__':
    main()
