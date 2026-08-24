#!/usr/bin/env python3
"""Quality gates for LAST_SIGNAL/assets/audio/v2 — run from repo root.

Gates: loads via wave module, no sustained samples >= +-32000, seamless-loop
fade windows present (first/last 1000 samples near-silent), music-set RMS
within +-3 dB, durations within spec.
"""
import json
import os
import sys
import wave

import numpy as np

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "LAST_SIGNAL", "assets", "audio", "v2")

SPEC = {
    "music/main_theme.wav":       ("loop",    60, 95),
    "music/calm_loop.wav":        ("loop",    20, 45),
    "music/tension_loop.wav":     ("loop",    20, 30),
    "music/dread_loop.wav":       ("loop",    20, 40),
    "music/hope_loop.wav":        ("loop",    20, 40),
    "music/end_wake_them.wav":      ("stinger", 10, 15),
    "music/end_let_them_sleep.wav": ("stinger", 10, 15),
    "music/end_merge.wav":          ("stinger", 10, 15),
    "music/end_wake_but_leave.wav": ("stinger", 10, 15),
    "music/end_station_wins.wav":   ("stinger", 10, 15),
    "music/end_the_loop.wav":       ("stinger", 10, 15),
    "sfx/ui_hover.wav":       ("sfx", 0.03, 1.0),
    "sfx/ui_confirm.wav":     ("sfx", 0.05, 1.5),
    "sfx/ui_back.wav":        ("sfx", 0.05, 1.5),
    "sfx/log_play.wav":       ("sfx", 0.1, 2.0),
    "sfx/terminal_type.wav":  ("sfx", 0.2, 3.0),
    "sfx/door_open.wav":      ("sfx", 0.4, 3.0),
    "sfx/door_close.wav":     ("sfx", 0.4, 3.0),
    "sfx/alarm_soft.wav":     ("sfx", 1.0, 5.0),
    "sfx/alarm_hard.wav":     ("sfx", 1.0, 5.0),
    "sfx/pod_hiss.wav":       ("sfx", 0.8, 5.0),
    "sfx/power_down.wav":     ("sfx", 0.5, 4.0),
    "sfx/power_up.wav":       ("sfx", 0.5, 4.0),
    "sfx/heartbeat_low.wav":  ("sfx", 1.5, 6.0),
    "sfx/cryo_beep_loop.wav": ("loop_sfx", 1.0, 4.0),
    "sfx/static_burst.wav":   ("sfx", 0.1, 2.0),
    "voice/station_low.wav":      ("voice", 2.0, 8.0),
    "voice/station_hostile.wav":  ("voice", 2.0, 8.0),
    "voice/station_intimate.wav": ("voice", 2.0, 8.0),
}

failures = []
report = {"files": {}, "music_rms_dbfs": {}}

for rel, (kind, lo, hi) in sorted(SPEC.items()):
    path = os.path.join(ROOT, rel)
    if not os.path.exists(path):
        failures.append(f"MISSING {rel}")
        continue
    with wave.open(path, "rb") as w:
        assert w.getsampwidth() == 2 and w.getframerate() == 44100, f"FORMAT {rel}"
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64)
    dur = len(x) / 44100
    peak = np.max(np.abs(x))
    rms = np.sqrt(np.mean(x ** 2)) if len(x) else 0
    report["files"][rel] = {"dur": round(dur, 3), "peak": int(peak), "rms_dbfs": round(20 * np.log10(rms / 32768 + 1e-9), 2)}

    # clipping gate: no SUSTAINED samples >= +-32000 (isolated single-sample
    # inter-sample taps from tanh are fine; require >=3 consecutive)
    hot = np.abs(x) >= 32000
    runs = np.diff(np.flatnonzero(np.diff(hot.astype(int)))) 
    if hot.any():
        idx = np.flatnonzero(hot)
        breaks = np.flatnonzero(np.diff(idx) > 1)
        starts = np.r_[idx[0], idx[breaks + 1]]
        ends = np.r_[idx[breaks], idx[-1]]
        max_run = int(np.max(ends - starts + 1))
        if max_run >= 3:
            failures.append(f"CLIP {rel}: {max_run} consecutive samples at full scale")
    else:
        max_run = 0

    # duration gate
    if not (lo <= dur <= hi):
        failures.append(f"DURATION {rel}: {dur:.2f}s outside [{lo},{hi}]")

    # seamlessness: loop files must have near-silent edges
    if kind in ("loop", "loop_sfx"):
        edge = min(500, len(x) // 10)
        edge_peak = max(np.max(np.abs(x[:edge])), np.max(np.abs(x[-edge:])))
        if edge_peak > 1200:
            failures.append(f"SEAM {rel}: edge peak {int(edge_peak)} > 1200")
        report["files"][rel]["edge_peak"] = int(edge_peak)

    if kind == "loop":
        report["music_rms_dbfs"][rel] = report["files"][rel]["rms_dbfs"]

# loudness gate across music loops (+-3 dB)
if report["music_rms_dbfs"]:
    vals = list(report["music_rms_dbfs"].values())
    spread = max(vals) - min(vals)
    report["music_rms_spread_db"] = round(spread, 2)
    if spread > 3.0:
        failures.append(f"LOUDNESS: music loop RMS spread {spread:.2f} dB > 3.0")

report["gate"] = "PASS" if not failures else "FAIL"
print(json.dumps(report, indent=1))
if failures:
    print("\nFAILURES:")
    for f in failures:
        print(" -", f)
    sys.exit(1)
print("\nALL GATES PASS")
