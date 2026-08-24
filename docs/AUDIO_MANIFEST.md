# AUDIO MANIFEST — Last Signal v2 (Wave 1)

All files are procedurally generated (see `tools/audiogen/gen_all.py`, fixed seeds)
at 44.1 kHz 16-bit mono WAV, living under `LAST_SIGNAL/assets/audio/v2/`.
v1 files in `assets/audio/` are untouched.

## Music loops — tension ladder

Crossfade between loops as narrative tension shifts. All share the A-minor
family at ~60 BPM so crossfades stay consonant. RMS loudness within ±3 dB
across the set (verified by `tools/audiogen/qc_gates.py`).

| ID | File | Duration | Trigger |
|----|------|----------|---------|
| `music/main_theme` | music/main_theme.wav | 72s | Main menu / title screen loop |
| `music/calm_loop` | music/calm_loop.wav | 30s | Default exploration; Prologue, quiet log-reading moments (Ch1) |
| `music/tension_loop` | music/tension_loop.wav | 24s | Station reveals itself; Ch2 "The Station Speaks", discovery of tampering |
| `music/dread_loop` | music/dread_loop.wav | 24s | `station_hostile` active; Ch3 truth revealed, Ch4 confrontation build-up |
| `music/hope_loop` | music/hope_loop.wav | 30s | `station_allied` path; cooperative beats in Ch2–Ch4 |

Suggested ladder: calm ↔ hope for low tension, tension for mid, dread for high.
Fade 2–4 s between levels; never hard-cut.

## Ending stingers

One per ending in docs/ending_tree.md. Play once over the epilogue card,
replacing (not layering over) the current music loop.

| ID | File | Duration | Ending |
|----|------|----------|--------|
| `music/end_wake_them` | music/end_wake_them.wav | 14s | ⭐ Wake Them — resolving major progression |
| `music/end_let_them_sleep` | music/end_let_them_sleep.wav | 13s | 💤 Let Them Sleep — fading lullaby fall |
| `music/end_merge` | music/end_merge.wav | 14s | 🔀 Merge — slow rising hybrid swell |
| `music/end_wake_but_leave` | music/end_wake_but_leave.wav | 12s | 🚀 Wake But Leave — bittersweet departure |
| `music/end_station_wins` | music/end_station_wins.wav | 13s | ☠️ Station Wins — dark descending collapse |
| `music/end_the_loop` | music/end_the_loop.wav | 11s | 🔄 The Loop — unresolved circular figure |

## SFX

| ID | File | Duration | Trigger |
|----|------|----------|---------|
| `sfx/ui_hover` | ui_hover.wav | 0.09s | Button hover |
| `sfx/ui_confirm` | ui_confirm.wav | 0.18s | Choice confirm / menu select |
| `sfx/ui_back` | ui_back.wav | 0.16s | Back / cancel navigation |
| `sfx/log_play` | log_play.wav | 0.38s | Crew log playback start (Ch1+ log viewer) |
| `sfx/terminal_type` | terminal_type.wav | ~0.5s | Typewriter text reveal on terminals/dialogue |
| `sfx/door_open` | door_open.wav | 1.1s | Scene transition into a station room |
| `sfx/door_close` | door_close.wav | 0.9s | Scene exit / sealed door behind player |
| `sfx/alarm_soft` | alarm_soft.wav | 2.7s | Caution alert: power warnings, suspicious readings |
| `sfx/alarm_hard` | alarm_hard.wav | 2.2s | `station_hostile` events; pod failure cascade (Station Wins) |
| `sfx/pod_hiss` | pod_hiss.wav | 2.2s | Cryo pod pressurization; wake-up sequence (Wake Them) |
| `sfx/power_down` | power_down.wav | 1.6s | Station dimming (Let Them Sleep), systems lost to Station |
| `sfx/power_up` | power_up.wav | 1.6s | Emergency boot (Prologue), diagnostic run |
| `sfx/heartbeat_low` | heartbeat_low.wav | 3.4s | High-tension underscore layer during Ch4 choice |
| `sfx/cryo_beep_loop` | cryo_beep_loop.wav | 2.0s (seamless) | Ambient bed for cryo bay scenes |
| `sfx/static_burst` | static_burst.wav | 0.5s | Log corruption stings; Station interrupting transmissions |

## Voice textures

Dark granular/reverberant processing in the register of the v1
`station_voice`. Texture beds only — no speech content. Layer under or over
Station Voice Overlay dialogue lines.

| ID | File | Duration | Trigger |
|----|------|----------|---------|
| `voice/station_low` | voice/station_low.wav | 5s | Neutral/suspicious Station dialogue underlay |
| `voice/station_hostile` | voice/station_hostile.wav | 4s | Hostile Station lines; threat moments |
| `voice/station_intimate` | voice/station_intimate.wav | 5s | Allied/intimate Station lines; Merge ending dialogue |

## Regeneration & QA

```
python3 tools/audiogen/gen_all.py      # regenerate all WAVs (fixed seeds)
python3 tools/audiogen/qc_gates.py     # quality gates (must print ALL GATES PASS)
```
