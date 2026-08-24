# AUDIO SYSTEM PROPOSAL — AudioManager API (v2)

PROPOSAL ONLY — the engine card owns implementation code; integrator reconciles.
Consumes the Wave 1 audio package (`docs/AUDIO_MANIFEST.md`,
`LAST_SIGNAL/assets/audio/v2/`).

## Node layout (suggested)

```
AudioManager (Node)
├── MusicA -> AudioStreamPlayer   # crossfade pair A/B, bus "Music"
├── MusicB -> AudioStreamPlayer
├── Sfx     -> AudioStreamPlayer  # polyphonic (AudioStreamPolyphonic) or N players, bus "SFX"
├── Ambience -> AudioStreamPlayer # looping beds, bus "Ambience"
└── Voice    -> AudioStreamPlayer # voice texture underlay, bus "Voice"
```

Preload all v2 WAVs at startup into an `id -> AudioStreamWAV` dict.
Loop points: WAV import loop enabled for `*loop*` IDs and `music/*_loop`.

## Proposed API

```gdscript
func play_music_id(id: StringName, fade := 3.0) -> void
    ## Crossfades to the given music ID using the idle member of the A/B pair.
    ## Same-id call is a no-op. Stinger IDs play once (no loop) then release
    ## the music bus back to silence.

func stop_music(fade := 2.0) -> void

func set_tension_level(level: int) -> void
    ## 0=calm 1=hope 2=tension 3=dread — convenience wrapper that maps to
    ## music/calm_loop..dread_loop with the standard 3s crossfade.

func play_sfx(id: StringName, volume_db := 0.0, pitch := 1.0) -> void
    ## Fire-and-forget one-shot on the SFX bus (ui_*, door_*, alarms, etc.).

func play_ambience(id: StringName) -> void
    ## Looping SFX beds (cryo_beep_loop). Passing "" stops ambience.

func play_voice(id: StringName, fade := 0.4) -> void
    ## Duck music by -6 dB, fade in voice texture; auto-release after length,
    ## restore prior music level.
```

## Behaviors

- Crossfade = linear gain ramps over `fade` seconds on both players;
  new stream starts from sample 0 (all loops are seamless).
- Stingers (`music/end_*`) bypass the loop flag: play once at full music
  volume, then leave music silent until explicitly resumed.
- All buses route through a master limiter so layered SFX cannot clip.
