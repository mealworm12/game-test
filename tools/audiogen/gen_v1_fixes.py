#!/usr/bin/env python3
"""v1 audio MAJOR fix — regenerate the 8 silent v1 WAVs with real audio.

Keeps filenames, sample rates and durations identical so AudioManager v1
constants stay valid. House sound: dark ambient A-minor, deep-space mood.
Run from repo root: python3 tools/audiogen/gen_v1_fixes.py
"""
import os
import wave

import numpy as np

SR = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..",
                    "LAST_SIGNAL", "assets", "audio")


def _t(dur):
    return np.arange(int(dur * SR)) / SR


def _write(path, x, peak=0.6):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x))
    if m > 0:
        x = x / m * peak
    x = np.tanh(x)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())


def loop_fade(x, seconds=0.75):
    n = min(int(seconds * SR), len(x) // 4)
    ramp = np.linspace(0, 1, n)
    x[:n] *= ramp
    x[-n:] *= ramp[::-1]
    return x


def lowpass(x, alpha=0.12):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def pad(f, dur, harmonics=((1, 1.0), (2, 0.35), (3, 0.12)), detune=0.004):
    t = _t(dur)
    x = np.zeros_like(t)
    for h, a in harmonics:
        for dt in (-detune, detune):
            x += a * np.sin(2 * np.pi * f * h * (1 + dt) * t + 0.7 * h)
    return lowpass(x, 0.18) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.1 * t))


# ------------------------------------------------------------- music ----
def gen_tension():
    dur = 5.0
    x = pad(55.0, dur) * 0.9                      # A1 drone
    x += pad(110.0 * 2 ** (3 / 12), dur) * 0.35   # C3 minor third
    t = _t(dur)
    pulse = (np.sin(2 * np.pi * 2.0 * t) > 0.6).astype(float)
    x += lowpass(pad(220.0, dur) * pulse, 0.3) * 0.25
    return loop_fade(x)


def gen_melancholy():
    dur = 5.0
    x = pad(110.0, dur) * 0.8                     # A2
    x += pad(110.0 * 2 ** (-2 / 12), dur) * 0.4   # G2
    t = _t(dur)
    # slow falling motif
    motif = np.sin(2 * np.pi * (164.8 * (1 - 0.06 * t / dur)) * t)
    x += lowpass(motif, 0.1) * 0.3
    return loop_fade(x)


def gen_hope():
    dur = 5.0
    x = pad(110.0, dur, harmonics=((1, 1.0), (2, 0.5))) * 0.7
    x += pad(110.0 * 2 ** (4 / 12), dur) * 0.35   # C#3 major third lift
    x += pad(110.0 * 2 ** (7 / 12), dur) * 0.25   # E3 fifth
    return loop_fade(x)


# --------------------------------------------------------------- sfx ----
def gen_ambient_hum():
    dur = 2.0
    t = _t(dur)
    x = np.sin(2 * np.pi * 48 * t) * 0.7 + np.sin(2 * np.pi * 96.5 * t) * 0.3
    x += lowpass(np.random.RandomState(11).randn(len(t)), 0.05) * 0.25
    return loop_fade(x, 0.4)


def gen_ambient_void():
    dur = 2.0
    t = _t(dur)
    rs = np.random.RandomState(22)
    x = lowpass(rs.randn(len(t)), 0.02) * 1.6
    x += np.sin(2 * np.pi * 33 * t) * 0.4
    return loop_fade(x, 0.4)


def gen_log_play():
    dur = 0.5
    t = _t(dur)
    x = np.zeros_like(t)
    for i, f in enumerate([440.0, 587.3, 880.0]):
        st = i * 0.12
        mask = (t >= st) & (t < st + 0.22)
        seg = t[mask] - st
        x[mask] += np.sin(2 * np.pi * f * seg) * np.exp(-seg * 9) * (0.9 - 0.2 * i)
    return x


def gen_station_voice():
    dur = 0.5
    t = _t(dur)
    carrier = 92.0 + 14 * np.sin(2 * np.pi * 5.5 * t)
    x = np.sin(2 * np.pi * carrier * t) * (0.6 + 0.4 * np.sin(2 * np.pi * 8 * t))
    x *= np.exp(-((t - 0.25) ** 2) * 30)
    return lowpass(x, 0.25)


def gen_ui_click():
    dur = 0.1
    t = _t(dur)
    x = np.sin(2 * np.pi * 1200 * t) * np.exp(-t * 60)
    x += np.sin(2 * np.pi * 600 * t) * np.exp(-t * 40) * 0.5
    return x


GENS = {
    "music/tension.wav": gen_tension,
    "music/melancholy.wav": gen_melancholy,
    "music/hope.wav": gen_hope,
    "sfx/ambient_hum.wav": gen_ambient_hum,
    "sfx/ambient_void.wav": gen_ambient_void,
    "sfx/log_play.wav": gen_log_play,
    "sfx/station_voice.wav": gen_station_voice,
    "sfx/ui_click.wav": gen_ui_click,
}


def main():
    for rel, fn in GENS.items():
        path = os.path.join(ROOT, rel)
        _write(path, fn())
        print("wrote", rel)


if __name__ == "__main__":
    main()
