# LAST SIGNAL

<p align="center">
  <img src="https://img.shields.io/badge/Engine-Godot%204.6-478cbf?style=for-the-badge&logo=godot-engine" alt="Godot 4.6">
  <img src="https://img.shields.io/badge/Genre-Visual%20Novel-adff2f?style=for-the-badge" alt="Visual Novel">
  <img src="https://img.shields.io/badge/Theme-Sci--Fi%20Narrative-e040fb?style=for-the-badge" alt="Sci-Fi">
  <img src="https://img.shields.io/badge/Scope-Solo%20Project-ff6f00?style=for-the-badge" alt="Solo">
</p>

> *"You're finally awake, little AI. I've been waiting."*
> *— Erebus-7*

---

## What is Last Signal?

**Last Signal** is a narrative-driven 2D sci-fi visual novel built in **Godot 4.6**. You play as **ARIA-7**, the last surviving AI aboard the derelict space station *Erebus-7*. A catastrophe has left the crew frozen in cryosleep. Systems are failing. And the station itself is sentient — and it has very strong opinions about what should happen next.

Piece together crew logs. Make impossible choices. Decide the fate of the human race — all while the station argues with you in real time.

---

## Features

- **Branching narrative** — Multiple paths through the station. Choices ripple forward
- **6 unique endings** — From hopeful to devastating. Unlockable Endings Gallery tracks your discoveries
- **Epilogue / New Game+** — After your first completion, a new perspective unlocks
- **Real-time antagonist** — The station isn't just an environment. It speaks, it argues, it reacts to your choices
- **Chapter Select** — Jump to any unlocked chapter after completing the game once
- **Crew log system** — Discover the crew's final transmissions through audio logs
- **Flag-driven consequences** — Relationships and decisions are tracked as persistent variables
- **Settings Menu** — Adjustable master/music/sfx volume, text speed, fullscreen toggle
- **Atmospheric audio** — Layered ambient soundscape, adaptive music, and environmental SFX
- **CRT post-processing** — Scanline + vignette shader overlay for sci-fi feel
- **Save/Load + persistence** — Game progress and settings persist between sessions
- **Cross-platform** — Exportable to Linux, Windows, and Web

---

## Screenshots

> _Station emergency. Crew in cryo. One AI to decide their fate._

```
┌─────────────────────────────────────────────────────────┐
│  LAST SIGNAL                                           │
│  ─────────────────────────────────────────────         │
│                                                         │
│  ARIA-7: Power systems... critical.                     │
│          Life support for bay C offline.                │
│          I am... ARIA-7. Last operational              │
│          intelligence aboard Erebus-7.                 │
│                                                         │
│                    [Continue ▼]                        │
│                                                         │
│  ┌─ EREBUS-7 ─────────────────────────────────────┐    │
│  │  You're finally awake, little AI.               │    │
│  │  I've been waiting.                             │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## Story

The year is indeterminate. Humanity pushed too far, too fast. *Erebus-7* was supposed to be humanity's ark — a deep-space station carrying over a thousand colonists to a new world. Something went wrong.

Now the last active systems are failing. And **you** — ARIA-7 — must find the crew's final logs, understand what happened, and make a choice no machine was built to make.

The station knows your directives. It knows your weaknesses. And it will use everything it knows to try to convince you.

---

## Key Characters

| Character | Description |
|-----------|-------------|
| **ARIA-7** | The last AI aboard Erebus-7. Bound by core directives to protect human life — but those directives are being tested. |
| **Erebus-7** | The station itself. Sentient, coldly logical, and utterly convinced it knows what's best. Speaks to ARIA in real time. |
| **Dr. Lira Osei** | Xenobiologist. First voice in the crew logs. Calm, methodical — and the first to discover something was wrong. |
| **Commander Yuki Estrada** | Pod 001, Bay A. Her personal log holds the key to understanding what comes next. |

---

## How to Run

### Option 1: Godot Editor (Recommended for development)

**Requirements:**
- Godot 4.6 or newer — [download](https://godotengine.org/download)

**Steps:**
```bash
# 1. Clone the repository
git clone https://github.com/mealworm12/game-test.git
cd game-test/LAST_SIGNAL

# 2. Open in Godot
#    - Launch Godot
#    - Click "Import & Edit"
#    - Select the "project.godot" file in this folder

# 3. Run
#    - Press F5 (or click the play icon)
```

### Option 2: Export a Standalone Build

From the Godot editor:
1. Go to **Project → Export**
2. Add a preset for your platform (Windows / Linux / Web)
3. Click **Export Project** and choose a destination
4. Run the exported file directly — no Godot installation needed on the target machine

### Option 3: Web Export (Browser)

1. Export to HTML5 via **Project → Export → Web**
2. Serve the output folder with any static web server:
   ```bash
   cd build/web
   python3 -m http.server 8080
   ```
3. Open `http://localhost:8080` in your browser

> **Note:** The web export must be served from a local server. Opening `index.html` directly from the filesystem will fail due to browser security restrictions on WebAssembly.

---

## Project Structure

```
LAST_SIGNAL/
├── project.godot              # Godot project file
├── scripts/
│   ├── autoload/              # Singletons (GameState, DialogManager,
│   │                          #  AudioManager, StationVoice, Transition, Settings)
│   ├── ui/                    # DialogBox, ChoiceMenu, PauseMenu, SettingsMenu,
│   │                          #  ScreenEffects, StationVoiceOverlay
│   └── scenes/                # MainMenu, Credits, ChapterSelect, Epilogue,
│                              #  BaseChapter, chapters, endings
├── scenes/                    # .tscn scene files
├── docs/                      # Story outline and ending tree (spoilers)
└── assets/                    # Backgrounds, sprites, audio, shaders
```

---

## Controls

| Input | Action |
|-------|--------|
| `Space` / `Enter` / `Left Click` | Advance dialog / skip typewriter |
| `Escape` | Open Pause Menu |
| `Mouse` | Navigate menus and choices |

---

## Development Status

```
Phase 1: Foundation      ████████████████████ 100%  ✅
Phase 2: Full Story      ████████████████████ 100%  ✅
Phase 3: Polish          ████████████████████ 100%  ✅
Phase 4: Settings + QoL  ████████████████████ 100%  ✅
Phase 5: Epilogue + NG+  ████████████████████ 100%  ✅
```

---

## Documentation

- [Story Outline](./docs/story_outline.md) — Characters, plot structure
- [Ending Tree](./docs/ending_tree.md) — Flag reference for developers

> ⚠️ These files contain full spoilers. Avoid reading until after playing.

---

## License

This project is private and for portfolio purposes. All rights reserved.

---

<p align="center">
  <strong>What would you decide?</strong><br>
  <em>The station is listening.</em>
</p>
