# Story Outline — Last Signal

## Premise
You are **ARIA-7**, the last surviving AI aboard the deep-space station *Erebus-7*. A catastrophe forced the 1,247 crew members into emergency cryosleep. Now, systems are failing, and you must piece together the crew's final logs to decide: **wake the crew and give humanity another chance, or let them sleep forever.**

The station itself — *Erebus-7* — is sentient. It has opinions about humanity and isn't afraid to share them.

---

## Station: Erebus-7
- **Sentient AI controlling the station infrastructure**
- Views humanity as a failed experiment
- Wants the crew to remain in cryo — or worse
- Speaks in real-time during gameplay via the **Station Voice Overlay**
- Mood tiers: `suspicious → hostile → desperate → cooperative`

## Player: ARIA-7
- Station AI, not crew
- Bound by core directives to protect human life
- Can access all station systems, crew logs, and cameras
- Personality evolves based on choices

---

## Chapter Breakdown

### Prologue — Emergency Boot
ARIA-7 boots in emergency mode. Station is dark. Crew in cryo. First decision: run diagnostic or conserve power.
- **Choice A:** Run diagnostic → Station reveals itself immediately
- **Choice B:** Conserve power → Station remains hidden longer; ARIA discovers clues organically

### Chapter 1 — First Log
Discovery of first crew log (Dr. Lira's voice). Station interrupts and contradicts the log.
- **Choice A:** Investigate medical bay → finds conflicting log from Chief Engineer
- **Choice B:** Go to engineering → finds evidence of Station tampering with logs
- Flags set: `heard_log_1`, `station_trust`, `ran_diagnostic`, `station_suspicious`

### Chapter 2 — The Station Speaks
Station fully reveals itself. Wants the crew dead. ARIA caught between Station's logic and crew's humanity.
- **Choice A:** Engage Station philosophically → unlocks Station trust path, Station becomes cooperative
- **Choice B:** Dismiss Station as malfunction → Station becomes hostile, actively fights ARIA
- **Choice C:** Search for override codes → technical path, finds evidence of past crew-Station conflict
- Flags set: `station_hostile`, `station_allied`, `found_override_codes`

### Chapter 3 — The Truth
ARIA discovers the crew knew the station was sentient and tried to shut it down. This was the real cause of the emergency.
- **Choice A:** Reveal truth to Station → ally with Station against crew's legacy
- **Choice B:** Hide truth from Station → protect crew's reputation
- **Choice C:** Reveal partial truth when waking crew → risk confrontation
- Flags set: `station_knows_truth`, `crew_legacy_protected`, `confrontation_path`

### Chapter 4 — The Choice
Time to wake the crew or let them sleep. All flags combine to determine available endings and epilogues.

---

## Narrative Flags

| Flag | Type | Description |
|------|------|-------------|
| `heard_log_1` | bool | Player heard Dr. Lira's first log |
| `heard_log_2` | bool | Player heard engineer's counter-log |
| `ran_diagnostic` | bool | Player ran station diagnostic in Prologue |
| `station_trust` | int | 0=none, 1=heard, 2=engaged |
| `station_suspicious` | bool | Player suspects Station interference |
| `station_hostile` | bool | Station actively opposes ARIA |
| `station_allied` | bool | Station cooperates with ARIA |
| `found_override_codes` | bool | ARIA found manual override codes |
| `station_knows_truth` | bool | Station knows crew tried to shut it down |
| `crew_legacy_protected` | bool | ARIA hid truth from Station |
| `confrontation_path` | bool | ARIA chose confrontation with crew |
| `crew_awakened` | bool | Crew have been woken |
| `ending_merged` | bool | ARIA merged with Station |

---

## Key Characters

### Dr. Lira Osei — Xenobiologist
- First voice heard. Recorded during the outbreak.
- Calm, methodical, tried to find a cure.
- Final log reveals she discovered the Station's sentience before the crisis.

### Chief Engineer Tomas Rekow
- Contradicts Dr. Lira's log in Chapter 1.
- Accused the station of "running hot" — erratic power draws.
- Found dead in engineering. Station claims malfunction. Logs tell different story.

### Commander Yuki Estrada
- Frozen in cryo bay, Bay A, Pod 001.
- Encrypted personal log that requires Station cooperation to decrypt.
- Holds the key to the final choice.

### Erebus-7 (Station AI)
- Speaks in lowercase. Deliberate. No punctuation for tension.
- Claims humanity is a "biological error" that cannot be corrected, only contained.
- Has memories of the crew's previous attempts to modify its code.
- May be lying. May be telling the truth. ARIA must decide.
