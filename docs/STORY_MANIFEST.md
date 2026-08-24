# Story Manifest — Last Signal v2 Wave 1

All content lives under `LAST_SIGNAL/content/v2/` in the dialog-command contract
(say / choice / set_flag / if_flag goto / label / sfx / music / voice / bg /
portrait / dive_start / dive_end / codex_unlock). Validate with
`python3 tools/story_lint.py` — must PASS before merge.

## Content files

| File | Trigger | Flags touched | Asset IDs referenced |
|------|---------|---------------|----------------------|
| `log_lira_deep.dlg` | After Ch1, requires `heard_log_1`; medical bay archive | reads `station_suspicious`; sets `v2_lira_pattern` | bg_medical; music/calm_loop; sfx/log_play |
| `log_rekow_resolve.dlg` | After Ch3 truth reveal; engineering sub-level | reads `station_hostile`, `station_allied`; sets `v2_rekow_verdict_station` / `v2_rekow_verdict_tragedy` / `v2_rekow_verdict_unknown` (mutually exclusive) | bg_engineering; music/tension_loop; sfx/log_play, sfx/static_burst |
| `log_minor_crew.dlg` | Between Ch2 and Ch3; residential deck triage | sets `v2_minor_logs_found` | bg_corridor; music/calm_loop; sfx/door_open, sfx/log_play, sfx/static_burst |
| `log_estrada_decrypt.dlg` | Ch3 cryo bay A; requires `found_override_codes`; branch on `station_allied` | reads `station_allied`; sets `v2_estrada_locked` / `v2_estrada_decrypted` | bg_cryobay; music/dread_loop, music/calm_loop; voice/station_low; sfx/cryo_beep_loop, sfx/terminal_type, sfx/log_play |
| `dive_shutdown.dlg` | Ch3; requires `station_knows_truth` AND `heard_log_1` | sets `v2_dive_shutdown_seen` | bg_bridge; music/dread_loop; voice/station_low; sfx/alarm_soft, sfx/terminal_type, sfx/power_down; dive_start dive_shutdown_order |
| `dive_awakening.dlg` | Requires `ran_diagnostic` AND (`v2_lira_pattern` OR `station_allied`) | reads both; sets `v2_dive_awakening_seen` | bg_void; music/main_theme, music/calm_loop; voice/station_intimate, station_low, station_hostile; sfx/static_burst, sfx/heartbeat_low; dive_start dive_first_awakening |
| `dive_catastrophe.dlg` | Requires `v2_dive_shutdown_seen` AND `found_override_codes` | sets `v2_dive_catastrophe_seen` | bg_engineering; music/tension_loop; voice/station_low; sfx/power_up, sfx/alarm_hard, sfx/power_down; dive_start dive_catastrophe_night |
| `ch4_prechoice.dlg` | Immediately before final choice; dominant path via flag priority hostile > allied > neutral | reads all three path flags; sets `v2_path_allied` / `v2_path_hostile` / `v2_path_neutral` | bg_observation; music/calm_loop, dread_loop, main_theme; portraits aria:*, erebus:*; voice/station_*; sfx/door_open |
| `epilogue_variants.dlg` | Appended beats per ending; each block gated per table below | reads gates; internal routing only (`v2_route_*` temps) | see per-block rows below |
| `codex_placement.dlg` | Prologue diagnostic OR first-log discovery | reads `ran_diagnostic` | bg_bridge; music/calm_loop; sfx/terminal_type |
| `codex_entries.txt` | Codex data pack consumed by codex_unlock ids | n/a (data file) | n/a |

## New flags (all v2_-prefixed)

`v2_lira_pattern`, `v2_rekow_verdict_station`, `v2_rekow_verdict_tragedy`,
`v2_rekow_verdict_unknown`, `v2_minor_logs_found`, `v2_estrada_locked`,
`v2_estrada_decrypted`, `v2_dive_shutdown_seen`, `v2_dive_awakening_seen`,
`v2_dive_catastrophe_seen`, `v2_path_allied`, `v2_path_hostile`,
`v2_path_neutral`. Plus mechanical routing temps `v2_route_N` emitted where an
unconditional branch was needed inside a contract without bare `goto`.

Canon flags referenced read-only: heard_log_1, ran_diagnostic, found_override_codes,
station_allied, station_hostile, station_knows_truth.

## Codex unlock placement map

| codex id | unlocked in |
|----------|-------------|
| codex_station_glossary | dive_awakening.dlg, codex_placement.dlg (diagnostic path) |
| codex_log_catalog | log_lira_deep.dlg, codex_placement.dlg |
| codex_lira_dossier | log_lira_deep.dlg, codex_placement.dlg |
| codex_rekow_dossier | log_rekow_resolve.dlg, codex_placement.dlg |
| codex_okonkwo_dossier, codex_vance_dossier, codex_ilves_dossier | log_minor_crew.dlg |
| codex_estrada_dossier, codex_charter_fragment | log_estrada_decrypt.dlg |
| codex_override_fragment | dive_catastrophe.dlg |
| codex_ending_hints | ch4_prechoice.dlg |

## Epilogue variant gates (12 total)

| Ending | Block | Gate |
|--------|-------|------|
| wake_them | wake_them_all_logs | `v2_minor_logs_found` |
| wake_them | wake_them_estrada | `v2_estrada_decrypted` |
| let_them_sleep | sleep_all_logs | `v2_minor_logs_found` |
| let_them_sleep | sleep_catastrophe_truth | `v2_dive_catastrophe_seen` |
| merge | merge_lira_pattern | `v2_lira_pattern` |
| merge | merge_awakening_memory | `v2_dive_awakening_seen` |
| wake_but_leave | leave_rekow_verdict | `v2_rekow_verdict_tragedy` |
| wake_but_leave | leave_minor_logs | `v2_minor_logs_found` |
| station_wins | wins_override_known | `found_override_codes` |
| station_wins | wins_logs_heard | `heard_log_1` |
| the_loop | loop_dives_seen | `v2_dive_shutdown_seen` |
| the_loop | loop_minor_logs | `v2_minor_logs_found` |

## Crew logs added: 10 individual log entries across 4 discovery scenes
(Lira supplemental x2, Rekow maintenance x4, Okonkwo/Vance/Ilves fragments x3,
Estrada decrypted final entry x1)

## Memory dives: 3 (shutdown order, first awakening, catastrophe night)

## Ending reachability note

All six v1 endings remain reachable unchanged: every v2 file is optional
discovery or additive gating that never removes a canon route. The Ch4
pre-choice scene terminates at a neutral handoff point (no forced choice) so it
slots before any ending walk.
