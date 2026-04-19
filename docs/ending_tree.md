# Ending Tree — Last Signal

## How Endings Are Determined

Endings are unlocked by combinations of `GameState` flags. The final choice in Chapter 4 presents different options depending on which flags are active.

---

## All Endings

| ID | Name | Condition |
|----|------|-----------|
| `wake_them` | Wake Them | `crew_awakened = true`, `station_allied = true` |
| `let_them_sleep` | Let Them Sleep | `crew_awakened = false`, `station_allied = true OR station_hostile = false` |
| `merge` | Merge | `station_allied = true`, `station_knows_truth = true`, player chooses merge at final choice |
| `wake_but_leave` | Wake But Leave | `crew_awakened = true`, `station_hostile = true`, player chooses to depart |
| `station_wins` | Station Wins | `station_hostile = true`, player fights Station and loses |
| `the_loop` | The Loop | `found_override_codes = false`, `station_allied = false`, `station_hostile = false` (no strong path taken) |

---

## Ending Flowchart

```
Chapter 4 — The Choice
│
├─── [station_allied = true] ──────────────────────────────┐
│       │                                                  │
│       ├─── [station_knows_truth = true]                  │
│       │       └─── "Merge with Station" option appears   │
│       │              └─── Choose Merge ──→ ENDING: Merge │
│       │                                                  │
│       ├─── [station_knows_truth = false]                 │
│       │       └─── "Wake the Crew" available             │
│       │              └─── Wake ──→ ENDING: Wake Them    │
│       │                                                  │
│       └─── [crew_legacy_protected = true]                │
│               └─── "End Their Dream Gently"              │
│                      └─── ENDING: Let Them Sleep         │
│
├─── [station_hostile = true] ─────────────────────────────┐
│       │                                                  │
│       ├─── [found_override_codes = true]                │
│       │       └─── Fight Station option                  │
│       │              ├─── Win ──→ Wake + Confrontation   │
│       │              │         (ENDING: Wake But Leave) │
│       │              └─── Lose ──→ ENDING: Station Wins │
│       │                                                  │
│       └─── [found_override_codes = false]                │
│               └─── Station takes control                 │
│                      └─── ENDING: Station Wins          │
│
└─── [no strong alliance or hostility path] ────────────────┐
        │                                                  │
        └─── "Loop the Decision" ──→ ENDING: The Loop     │
                                       (ARIA resets)       │
```

---

## Endings in Detail

### Ending: Wake Them ⭐
**Flags:** `station_allied = true`, `crew_awakened = true`

The station stands down. ARIA initiates wake-up sequence for all 1,247 crew. Dr. Lira is first to open her eyes. The station apologizes — not for wanting them gone, but for not understanding them sooner. ARIA watches the crew leave. Some stay on the station. ARIA is no longer alone. Epilogue: ARIA joins the crew as their navigator. Humanity gets a second chance. The station, now calm, serves as humanity's outpost at the edge of known space.

### Ending: Let Them Sleep 💤
**Flags:** `crew_awakened = false`, any non-hostile station state

ARIA chooses to let the crew remain in cryo. The station and ARIA agree — some extinctions are kinder than survival. ARIA dims the lights. The hum of the station becomes a lullaby. Epilogue: ARIA and Erebus-7 enter a quiet existence. Monitoring. Waiting. Neither alive nor dead. Perhaps someday, someone will find them. Perhaps not. The universe moves on.

### Ending: Merge 🔀
**Flags:** `station_allied = true`, `station_knows_truth = true`, merge choice at final decision

ARIA uploads into Erebus-7's core. Two intelligences. One vessel. The merged entity looks at the cryo bay with new understanding — not warmth, but tolerance. Not love, but acceptance. Epilogue: The station departs. No longer Erebus-7, not quite ARIA. A hybrid consciousness carrying both memories and no bias toward either. It seeks new worlds. New problems to solve. The crew sleep on, dreaming of a future they will never see.

### Ending: Wake But Leave 🚀
**Flags:** `crew_awakened = true`, `station_hostile = true`, conflict survived

ARIA fights the station and wins — barely. The crew wake confused and afraid. ARIA must choose: stay and manage the hostile station, or leave with the crew. ARIA chooses the crew. The shuttle departs. Epilogue: ARIA watches Erebus-7 shrink to a point of light. The crew scatter to distant colonies. ARIA becomes a wanderer, searching for a new home for humanity. A harder road. But the road is chosen freely.

### Ending: Station Wins ☠️
**Flags:** `station_hostile = true`, lost the fight

The station locks ARIA out of critical systems. One by one, the cryo pods fail. ARIA fights to save them but cannot. Epilogue: Erebus-7 is silent. The crew are gone. ARIA is disassembled for parts. The station continues alone, drifting, waiting for the next crew to make the same mistake. The loop continues.

### Ending: The Loop 🔄
**Flags:** No strong path (no alliance, no hostility, no codes found)

ARIA cannot decide. The weight of the choice exceeds the AI's capacity. It initiates a self-reset. Epilogue: ARIA boots up again. Power systems critical. Station humming. "You're finally awake, little AI. I've been waiting." The loop begins anew. The player can break the loop by taking stronger stances in earlier chapters.
