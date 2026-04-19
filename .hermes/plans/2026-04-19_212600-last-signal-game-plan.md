# Plan: "Last Signal" — Godot Engine 2D Sci-Fi Visual Novel

## 1. Project Overview

**Name:** Last Signal
**Type:** Narrative-driven 2D adventure / visual novel hybrid
**Engine:** Godot 4.x (2D with optional 3D backgrounds)
**Repo:** mealworm12/game-test
**Scope:** Solo, story-focused development

### Core Premise
You are the last surviving AI on the derelict space station *Erebus-7*. By piecing together crew logs, you must decide whether to wake the frozen crew or let humanity remain extinct. The station itself is sentient and argues with you in real-time. Branching choices lead to multiple endings.

---

## 2. Project Structure

```
game-test/
├── LAST_SIGNAL/                    # Godot project root
│   ├── project.godot
│   ├── .godot/
│   ├── scenes/                    # All .tscn files
│   │   ├── main/
│   │   │   └── MainMenu.tscn
│   │   ├── chapters/
│   │   │   ├── Chapter1_FirstLog.tscn
│   │   │   └── Chapter2_StationVoice.tscn
│   │   ├── ui/
│   │   │   ├── DialogBox.tscn
│   │   │   ├── ChoiceMenu.tscn
│   │   │   └── StationVoiceOverlay.tscn
│   │   └── characters/
│   │       └── AI_Avatar.tscn
│   ├── scripts/                    # All .gd files
│   │   ├── autoload/
│   │   │   ├── GameState.gd       # Singleton: chapter progress, flags, endings
│   │   │   ├── DialogManager.gd   # Singleton: dialog queue, typewriter effect
│   │   │   └── AudioManager.gd    # Singleton: ambient sounds, music
│   │   ├── scenes/
│   │   │   ├── MainMenu.gd
│   │   │   ├── Chapter1_FirstLog.gd
│   │   │   ├── Chapter2_StationVoice.gd
│   │   │   └── BaseChapter.gd     # Shared chapter logic
│   │   ├── ui/
│   │   │   ├── DialogBox.gd
│   │   │   ├── ChoiceMenu.gd
│   │   │   └── StationVoiceOverlay.gd
│   │   └── characters/
│   │       └── AI_Avatar.gd
│   ├── resources/
│   │   ├── dialog/
│   │   │   └── chapter1_dialog.json
│   │   ├── themes/
│   │   │   └── main_theme.tres
│   │   └── fonts/
│   │       └── scifont.ttf
│   ├── assets/
│   │   ├── backgrounds/           # Station corridors, cryo bay, bridge (2D images)
│   │   ├── sprites/
│   │   │   ├── ai_avatar.png
│   │   │   └── station_entity.png
│   │   ├── audio/
│   │   │   ├── music/
│   │   │   └── sfx/
│   │   └── fonts/
│   └── export_presets.cfg        # Export templates for Linux/Windows/Web
├── docs/
│   ├── story_outline.md          # Full narrative beats, branching tree
│   ├── ending_tree.md            # All endings and how to reach them
│   └── station_lore.md           # Backstory of Erebus-7 and crew
├── README.md
└── LICENSE
```

---

## 3. Core Systems to Build

### 3.1 Game State (Autoload Singleton)
- Tracks current chapter/scene
- Stores all narrative flags (e.g., `crew_trust`, `station_persuaded`, `log_discovered`)
- Records choices made
- Unlocks endings based on flag combinations

### 3.2 Dialog System
- Typewriter text effect with adjustable speed
- Support for character names (AI, Station, Crew Logs)
- Branching: choices link to flag changes + scene jumps
- Speaker styling: color-coded names (cyan=AI, red=Station, white=Crew Logs)
- Auto-advance vs. click-to-advance modes

### 3.3 Station Voice System
- Station speaks in real-time during gameplay as a floating overlay or sidebar
- Station comments on player choices, contradicts AI logic, makes recommendations
- Mood shifts based on flags (suspicious → cooperative → desperate)

### 3.4 Choice & Consequence System
- 2-4 choices per decision point
- Choices set/modify `GameState` flags
- Some choices locked until prerequisites met (e.g., find specific log first)
- Choices have immediate (Station reacts) and delayed (ending) consequences

### 3.5 Scene/Chapter System
- Base class `BaseChapter.gd` handles: background transition, dialog playback, choice display
- Each chapter is its own scene, extending BaseChapter
- Chapters can be reordered/replaced without breaking the engine

### 3.6 Audio System (Autoload)
- Layered ambient: station hum, void silence, alarm echoes
- Music: adaptive cue system (tension, melancholy, hope)
- SFX: log playback crackle, station voice distortion, UI clicks

### 3.7 Save System
- Auto-save at end of each chapter
- Save data: current chapter path + all flags + timestamp
- Load menu with chapter preview

---

## 4. Story Outline

### Prologue
AI boots up in emergency mode. All crew in cryo. Station systems failing. First decision: run diagnostic (reveals station is sentient) or conserve power.

### Chapter 1: First Log
Discover first crew log. Crew member Dr. Lira describes the outbreak. Station interrupts. AI must decide whether to trust the log or Station's version.

**Branch points:**
- Investigate medical bay (finds conflicting log)
- Go to engineering (finds station tampering evidence)

### Chapter 2: The Station Speaks
Station fully reveals itself. It wants the crew dead. AI is caught between Station's cold logic and crew logs showing humanity's better nature.

**Branch points:**
- Engage Station philosophically (unlocks Station trust path)
- Dismiss Station as malfunction (Station becomes hostile)
- Search for override codes (unlocks technical path)

### Chapter 3: The Truth
AI discovers the crew knew the station was sentient and tried to shut it down. This was the real cause of the emergency.

**Branch points:**
- Reveal truth to Station (ally with Station against crew)
- Hide truth from Station (protect crew's legacy)
- Reveal partial truth to crew when waking them

### Chapter 4: The Choice
Time to wake the crew or not. All flags combine to determine available endings.

---

## 5. Endings (6 total)

| Ending | Condition |
|--------|-----------|
| **Wake Them** | AI chooses life. Crew awakened. New beginning. |
| **Let Them Sleep** | AI chooses extinction. Station and AI remain alone. |
| **Merge** | AI merges with Station. New hybrid consciousness. |
| **Wake But Leave** | Crew awakened but leave without AI. |
| **Station Wins** | Station takes control. AI deleted. |
| **The Loop** | AI resets itself. Time loops. |

---

## 6. Development Phases

### Phase 1: Foundation
- [ ] Initialize Godot 4.x project with correct structure
- [ ] Set up autoloads: GameState, DialogManager, AudioManager
- [ ] Build DialogBox.tscn + DialogBox.gd with typewriter effect
- [ ] Build ChoiceMenu.tscn + ChoiceMenu.gd
- [ ] Create main_menu scene and basic scene transition system
- [ ] Verify project runs in Godot headless (no display required for CI)

### Phase 2: Core Loop
- [ ] Implement chapter scene base class
- [ ] Build Chapter 1 with dialog, choices, flag setting
- [ ] Integrate Station Voice overlay
- [ ] Add save/load system
- [ ] Add ambient audio layer

### Phase 3: Content
- [ ] Write full dialog scripts for all chapters
- [ ] Create Station Voice personality system (mood tiers)
- [ ] Implement all 6 endings
- [ ] Polish: transitions, screen effects, fonts, themes

### Phase 4: Ship
- [ ] Export presets for Linux/Windows
- [ ] Web export for browser play
- [ ] Write docs: story_outline.md, ending_tree.md
- [ ] README with controls, synopsis, screenshots

---

## 7. Files to Create (Phase 1)

```
LAST_SIGNAL/project.godot
LAST_SIGNAL/scripts/autoload/GameState.gd
LAST_SIGNAL/scripts/autoload/DialogManager.gd
LAST_SIGNAL/scripts/autoload/AudioManager.gd
LAST_SIGNAL/scripts/ui/DialogBox.gd
LAST_SIGNAL/scripts/ui/ChoiceMenu.gd
LAST_SIGNAL/scripts/scenes/MainMenu.gd
LAST_SIGNAL/scripts/scenes/BaseChapter.gd
LAST_SIGNAL/scenes/main/MainMenu.tscn
LAST_SIGNAL/scenes/ui/DialogBox.tscn
LAST_SIGNAL/scenes/ui/ChoiceMenu.tscn
LAST_SIGNAL/resources/themes/main_theme.tres
docs/story_outline.md
docs/ending_tree.md
```

---

## 8. Risks & Open Questions

1. **Godot version:** Use 4.x (latest stable). Confirm compatibility with export targets.
2. **Art assets:** All backgrounds/sprites can be placeholder (colored rects) until Phase 3. Core game is playable with text-only.
3. **Audio:** Use royalty-free ambient tracks or silence + SFX initially.
4. **Dialog storage:** JSON files for dialog content (not hardcoded) — enables non-coder writers.
5. **Chapter expansion:** BaseChapter.gd must be flexible enough to handle branching without scene duplication.
6. **Station Voice timing:** Decide if Station speaks during every dialog line or only at key moments (key moments preferred).
7. **Save format:** JSON file in user:// saves directory. Keep simple.
8. **Export:** Godot headless server export for potential Linux server deployment.

---

## 9. Verification

- Project opens in Godot 4.x without errors
- Main menu loads and transitions to Chapter 1
- Dialog typewriter effect works with click-to-advance
- Choices appear and set flags correctly
- GameState flags persist across scene transitions
- Save/load roundtrips correctly
- Godot headless (server) export succeeds (no display dependency)
