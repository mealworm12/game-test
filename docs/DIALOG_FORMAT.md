# Last Signal - Dialog Format v2 (DIALOG_FORMAT.md)

Authoritative contract for v2 content scripts. The story card writes
plain-text script files; DialogManager parses and executes them line by
line via `DialogManager.run_script(script_text)`.

- One command per line. Blank lines and lines starting with `#` or `//`
  are comments and ignored.
- Arguments after the command name are separated by single spaces.
- `|` separates sub-fields within an argument list.
- All text must be ASCII (project quality bar).
- Unknown commands log a warning and are skipped (never crash).

## Commands

### say <speaker>|<text>
Displays a dialog line with typewriter effect. Blocks until advanced.
Speaker is matched by name (case-insensitive): `ARIA-7`, `EREBUS-7`,
`[CREW LOG]`, or anything else = narrator.
```
say ARIA-7|Systems check complete. All pods nominal.
say EREBUS-7|I have been waiting, little ghost.
```

### choice <prompt>|<opt>|<opt>|...
Pauses the script until the player picks an option. Each option is
either plain label text or `Label->label_name` to jump to a script
label. Options may set flags in the story data layer by pairing with
`set_flag` at the jump target.
```
choice Wake them?|Wake the crew->wake_path|Leave them sleeping->sleep_path
```

### set_flag <flag> [on|off|<value>]
Sets a narrative flag on GameState (default `on`). Non-on/off values
are stored as strings.
```
set_flag crew_trust_high
set_flag reactor_diverted off
```

### if_flag <flag> goto <label>
Conditional jump when the flag is truthy; falls through otherwise.
```
if_flag crew_trust_high goto trust_ending_branch
```

### label <name>
Jump target for `choice ...->name` and `if_flag ... goto name`.
```
label wake_path
```

### sfx|music|voice <id>
Audio hooks against docs/AUDIO_MANIFEST.md IDs. Missing files log and
continue.

Music IDs: main_theme, calm_loop, tension_loop, dread_loop, hope_loop,
end_* (ending stingers per audio card spec).

SFX IDs: ui_hover, ui_confirm, ui_back, log_play, terminal_type,
door_open, door_close, alarm_soft, alarm_hard, pod_hiss, power_down,
power_up, heartbeat_low, cryo_beep_loop, static_burst.

Voice IDs: station_low, station_hostile, station_intimate.
```
music dread_loop
sfx pod_hiss
voice station_low
```

### bg <path>
Changes the chapter background. Path is a res:// texture path; missing
textures are skipped with a log line.
```
bg res://assets/sprites/bg_bridge.png
```

### portrait <who>:<expr>
Triggers a portrait transition (fade/slide handled by presentation
layer) for character `<who>` with expression `<expr>` e.g. `neutral`,
`alarmed`, `sad`.
```
portrait ARIA-7:alarmed
```

### dive_start / dive_end
Enters/exits "dive" mode - triggers a screen-glitch transition on the
ScreenEffects layer.
```
dive_start
...memory dive content...
dive_end
```

### codex_unlock <entry_id>
Unlocks an archive entry (Codex autoload). Unknown IDs warn and skip.
```
codex_unlock crew_log_kowalski_01
```

## Example

```
# Chapter 2 opening
music calm_loop
bg res://assets/sprites/bg_medbay.png
label start
say ARIA-7|Another cycle. The hum has not changed.
sfx terminal_type
if_flag met_station goto station_interrupt
say ARIA-7|Maybe today I will open a pod.
jump not supported - use labels + choices only
codex_unlock medbay_records
```

Note: there is no unconditional `goto`; use a flag:
`set_flag tmp` then `if_flag tmp goto target`.
