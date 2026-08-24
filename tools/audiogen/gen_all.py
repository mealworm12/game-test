#!/usr/bin/env python3
"""Last Signal v2 audio package — procedural synthesis (fixed seeds).

Generates all Wave 1 IDs into LAST_SIGNAL/assets/audio/v2/:
  music/*.wav   seamless loops + ending stingers
  sfx/*.wav     interface / station SFX
  voice/*.wav   dark granular voice textures (texture only, no speech)

All 44.1 kHz 16-bit mono WAV. Run from repo root: python3 tools/audiogen/gen_all.py
"""
import os
import wave

import numpy as np

SR = 44100
OUT_ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "LAST_SIGNAL", "assets", "audio", "v2")

# Shared musical family: A minor pentatonic-ish, slow tempo so loops crossfade.
KEY = 110.0          # A2
TEMPO = 60           # BPM shared by all music
BEAT = 60.0 / TEMPO


def _t(dur):
    return np.arange(int(dur * SR)) / SR


def _write(path, x, peak=0.72):
    """Normalize to peak, hard-limit, write 16-bit WAV."""
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x))
    if m > 0:
        x = x / m * peak
    # soft clip any residual overshoot well below the +-32000 gate
    x = np.tanh(x)
    data = (np.clip(x, -1.0, 1.0) * 32767).astype(np.int16)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def loop_fade(x, seconds=1.0):
    """Apply equal-power fade windows so the sample is seamless when looped."""
    n = int(seconds * SR)
    if n * 2 > len(x):
        n = len(x) // 4
    ramp = np.linspace(0, 1, n)
    x[:n] *= ramp
    x[-n:] *= ramp[::-1]
    return x


def env_ad(n, a, d):
    e = np.ones(n)
    na, nd = int(a * SR), int(d * SR)
    e[:na] = np.linspace(0, 1, na)
    e[n - nd:] *= np.linspace(1, 0, nd) ** 2
    return e


def tone(f, dur, detune=0.0, harmonics=((1, 1.0),)):
    t = _t(dur)
    x = np.zeros_like(t)
    for h, amp in harmonics:
        for dt in (-detune, detune) if detune else (0.0,):
            x += amp * np.sin(2 * np.pi * f * h * (1 + dt) * t + h)
    return x


def lowpass(x, alpha=0.15):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


# ---------------------------------------------------------------- music ----

def chord_pad(freqs, dur, rng, brightness=3, vibrato=0.15):
    t = _t(dur)
    vib = 1 + 0.002 * np.sin(2 * np.pi * vibrato * t + rng.uniform(0, 6))
    x = np.zeros_like(t)
    for f in freqs:
        for h in range(1, brightness + 1):
            amp = 1.0 / h ** 1.7
            ph = rng.uniform(0, 6.28)
            x += amp * np.sin(2 * np.pi * f * h * t * vib + ph)
    # slow breathing amplitude
    x *= 0.8 + 0.2 * np.sin(2 * np.pi * (1 / dur) * t * rng.integers(1, 3))
    return x


def make_loop(name, chords, seed, dur_per_chord=8.0, brightness=3, sub=True):
    """chords: list of frequency lists; output is one seamless bar-loop."""
    rng = np.random.default_rng(seed)
    parts = [chord_pad(c, dur_per_chord, rng, brightness) for c in chords]
    x = np.concatenate(parts)
    # gentle noise air bed
    air = lowpass(rng.standard_normal(len(x)), 0.02) * 0.05
    x = 0.9 * x + air
    if sub:
        t = _t(len(x) / SR)
        x += 0.25 * np.sin(2 * np.pi * KEY / 2 * t)
    return loop_fade(x, 1.5)


A_MIN = [KEY, KEY * 1.189, KEY * 1.498]              # Am
F_MAJ = [KEY * 0.844, KEY * 1.0, KEY * 1.26]         # F
C_MAJ = [KEY * 0.667 * 1.5, KEY * 1.26 * 1.5 / 1.5, KEY * 1.498]   # C-ish
E_MIN = [KEY * 1.498, KEY * 1.782, KEY * 2.245]      # Em
G_MAJ = [KEY * 1.888, KEY * 2.245, KEY * 2.52]       # G
D_MIN = [KEY * 1.122, KEY * 1.335, KEY * 1.682]      # Dm

def gen_music():
    out = {}
    out["main_theme"] = make_loop(
        "main_theme",
        [A_MIN, F_MAJ, C_MAJ, E_MIN, A_MIN, F_MAJ, D_MIN, E_MIN],
        seed=101, dur_per_chord=9.0, brightness=4)
    out["calm_loop"] = make_loop("calm_loop", [A_MIN, F_MAJ, C_MAJ], seed=102,
                                 dur_per_chord=10.0, brightness=3)
    out["tension_loop"] = make_loop("tension_loop", [D_MIN, E_MIN, D_MIN, E_MIN],
                                    seed=103, dur_per_chord=6.0, brightness=5, sub=False)
    out["dread_loop"] = make_loop("dread_loop", [[KEY * .5, KEY * .594], [KEY * .5, KEY * .63]],
                                  seed=104, dur_per_chord=12.0, brightness=2)
    out["hope_loop"] = make_loop("hope_loop", [C_MAJ, G_MAJ, F_MAJ, C_MAJ], seed=105,
                                 dur_per_chord=7.5, brightness=5, sub=False)
    return out


def stinger(chords, seed, total=12.0, rise=False, fall=False):
    """Emotional capstone: sustained progression that swells then resolves."""
    rng = np.random.default_rng(seed)
    total = int(total * SR) / SR  # snap to whole samples
    n_ch = len(chords)
    d = total / n_ch
    parts = []
    for i, c in enumerate(chords):
        seg = chord_pad(c, d, rng, brightness=4)
        shape = np.linspace(0.55, 1.0, len(seg)) if rise else (
            np.linspace(1.0, 0.45, len(seg)) if fall else np.ones(len(seg)))
        parts.append(seg * shape)
    x = np.concatenate(parts)
    t = _t(len(x) / SR)
    swell = np.minimum(t / 2.0, 1.0) * np.minimum((total - t) / 2.5, 1.0)
    x *= np.clip(swell, 0.12, 1.0)
    x += lowpass(rng.standard_normal(len(x)), 0.03) * 0.04 * swell
    # final resolve note
    tail = tone(KEY, 3.0, harmonics=((1, 1), (2, 0.4), (3, 0.2))) * env_ad(int(3 * SR), 0.05, 2.6) * 0.5
    x[-len(tail):] += tail
    return loop_fade(x, 0.8)


def gen_stingers():
    return {
        "end_wake_them":       stinger([C_MAJ, G_MAJ, A_MIN, F_MAJ, C_MAJ], 201, 14.0),
        "end_let_them_sleep":  stinger([A_MIN, F_MAJ, A_MIN, D_MIN], 202, 13.0, fall=True),
        "end_merge":           stinger([A_MIN, E_MIN, F_MAJ, E_MIN, A_MIN], 203, 14.0, rise=True),
        "end_wake_but_leave":  stinger([D_MIN, F_MAJ, C_MAJ, G_MAJ], 204, 12.0),
        "end_station_wins":    stinger([[KEY * .5, KEY * .561], [KEY * .47, KEY * .53]], 205, 13.0, fall=True),
        "end_the_loop":        stinger([A_MIN, E_MIN, A_MIN], 206, 11.0),
    }


# ------------------------------------------------------------------ sfx ----

def gen_sfx():
    out = {}

    def blip(f0, f1, dur, ring=0.4, harm=((1, 1), (2, .3))):
        t = _t(dur)
        f = f0 * (f1 / f0) ** (t / dur)
        ph = 2 * np.pi * np.cumsum(f) / SR
        x = sum(a * np.sin(ph * h + h) for h, a in harm)
        return x * env_ad(len(t), 0.004, dur - 0.01) * (ring ** (t * 3))

    out["ui_hover"] = blip(900, 1200, 0.09) * 0.35
    out["ui_confirm"] = blip(600, 900, 0.18) + 0.4 * blip(900, 1350, 0.18)
    out["ui_back"] = blip(700, 420, 0.16) * 0.8
    out["log_play"] = np.concatenate([blip(500, 750, 0.1), np.zeros(int(0.06 * SR)),
                                      blip(750, 1000, 0.22)]) * 0.7

    rng = np.random.default_rng(301)
    # terminal_type: burst of filtered ticks
    ticks = []
    for _ in range(9):
        tick = rng.standard_normal(int(0.018 * SR)) * env_ad(int(0.018 * SR), 0.001, 0.017)
        ticks.append(lowpass(tick, 0.4) * rng.uniform(0.5, 1.0))
        ticks.append(np.zeros(rng.integers(int(0.02 * SR), int(0.07 * SR))))
    out["terminal_type"] = lowpass(np.concatenate(ticks), 0.5) * 1.5

    def door(open_=True):
        d = 1.1 if open_ else 0.9
        n = int(d * SR)
        rumble = lowpass(rng.standard_normal(n), 0.01) * 2.2
        sweep = blip(180, 320 if open_ else 120, d, ring=0.15)
        clack = lowpass(rng.standard_normal(int(0.05 * SR)), 0.6) if not open_ else np.zeros(int(0.05 * SR))
        body = (rumble * env_ad(n, 0.08, d - 0.15)) + sweep * 0.5
        if not open_:
            body[-len(clack):] += clack * 2.5
        return body

    out["door_open"] = door(True)
    out["door_close"] = door(False)

    def alarm(period, cycles, harshness):
        seg = int(period * SR)
        t = _t(period)
        mod = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 1.6 * t))
        f = 620 + harshness * 380
        x = np.sin(2 * np.pi * f * t) * mod
        x += harshness * 0.4 * np.sin(2 * np.pi * f * 1.5 * t) * mod
        x = np.tile(x, cycles) * env_ad(seg * cycles, 0.01, period * cycles - 0.05)
        return x

    out["alarm_soft"] = alarm(0.9, 3, 0.0) * 0.5
    out["alarm_hard"] = alarm(0.55, 4, 1.0) * 0.75

    hiss = lowpass(rng.standard_normal(int(2.2 * SR)), 0.25)
    hp_env = env_ad(len(hiss), 0.02, 2.0)
    out["pod_hiss"] = hiss * hp_env * 1.4 + 0.3 * blip(300, 150, 2.2, ring=0.05)

    def power(up):
        d = 1.6
        t = _t(d)
        f0, f1 = (80, 480) if up else (480, 70)
        f = f0 * (f1 / f0) ** (t / d)
        x = np.sin(2 * np.pi * np.cumsum(f) / SR)
        hum = lowpass(rng.standard_normal(len(t)), 0.05)
        shape = np.linspace(0.3, 1, len(t)) if up else np.linspace(1, 0.25, len(t))
        return (x * 0.6 + hum * 0.8) * shape * env_ad(len(t), 0.03, d - 0.1)

    out["power_down"] = power(False)
    out["power_up"] = power(True)

    hb = int(0.95 * SR)
    beat = lowpass(blip(65, 50, 0.28, ring=0.05), 0.3)
    thump = np.zeros(hb)
    thump[:len(beat)] += beat * 2.2
    off = int(0.32 * SR)
    thump[off:off + len(beat)] += beat * 1.5
    out["heartbeat_low"] = np.tile(thump, 4)[:int(3.4 * SR)]

    cb = int(2.0 * SR)
    cryo = np.zeros(cb)
    beep = blip(1180, 1180, 0.09) * 0.5
    cryo[:len(beep)] += beep
    cryo[int(1.0 * SR):int(1.0 * SR) + len(beep)] += beep * 0.85
    bed = lowpass(np.random.default_rng(302).standard_normal(cb), 0.008)
    bed -= bed.mean()
    bed *= 0.4 / max(np.max(np.abs(bed)), 1e-9)
    x = loop_fade(cryo + bed, 0.25)
    x[:200] = 0
    x[-200:] = 0
    out["cryo_beep_loop"] = x

    sb = rng.standard_normal(int(0.5 * SR))
    gate = env_ad(len(sb), 0.001, 0.42) * (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 9 * _t(0.5))))
    out["static_burst"] = lowpass(sb * gate, 0.5) * 2.0
    return out


# ---------------------------------------------------------------- voice ----

def voice_texture(seed, pitch, rate, reverb, granular, dur=4.5):
    """Dark reverberant texture band evoking station_voice — no speech content."""
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    t = _t(dur)
    # formant-like drone: stacked sines around a low carrier with irregular AM
    x = np.zeros(n)
    for mult, amp in ((1, 1.0), (1.98, 0.5), (2.97, 0.28), (4.1, 0.14)):
        jitter = 1 + 0.01 * np.cumsum(rng.standard_normal(n)) / n * 40
        x += amp * np.sin(2 * np.pi * pitch * mult * t * jitter + rng.uniform(0, 6))
    am = 0.35 + 0.65 * np.abs(np.sin(2 * np.pi * rate * t + rng.uniform(0, 6)))
    x *= am
    if granular:
        # chop into grains and scatter playback positions (dark shimmer)
        g = int(0.06 * SR)
        y = np.copy(x)
        for start in range(0, n - g, g):
            src = int(np.clip(start + rng.normal(0, g * granular), 0, n - g))
            y[start:start + g] = x[src:src + g] * np.hanning(g) ** 0.3
        x = y
    x = lowpass(x, 0.08)
    # simple feedback delay "reverb"
    dly = int(reverb * SR)
    wet = np.copy(x)
    for k in range(1, 6):
        att = reverb ** k * 0.5
        shifted = np.zeros(n)
        shifted[k * dly:] = x[:-k * dly] if k * dly < n else 0
        wet += att * shifted
    return wet * env_ad(n, 0.4, 1.2)


def gen_voice():
    return {
        "voice/station_low":      voice_texture(401, 62, 0.7, 0.09, 0.0, 5.0),
        "voice/station_hostile":  voice_texture(402, 78, 2.6, 0.05, 0.9, 4.0),
        "voice/station_intimate": voice_texture(403, 55, 1.1, 0.14, 0.4, 5.0),
    }


def main():
    sets = [("music", {**gen_music(), **gen_stingers()}),
            ("sfx", gen_sfx()),
            ("voice", gen_voice())]
    written = []
    for subdir, items in sets:
        for name, x in items.items():
            rel = os.path.join(subdir, name.split("/")[-1] + ".wav")
            path = os.path.join(OUT_ROOT, rel)
            _write(path, x)
            written.append((name, rel, len(x) / SR))
    for name, rel, dur in sorted(written):
        print(f"{name:26s} -> assets/audio/v2/{rel}  ({dur:.2f}s)")


if __name__ == "__main__":
    main()
