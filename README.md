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

**Last Signal** is a narrative-driven 2D sci-fi visual novel built in Godot 4.x. You play as **ARIA-7**, the last surviving AI aboard the derelict space station *Erebus-7*. A catastrophe has left 1,247 crew members frozen in cryosleep. Systems are failing. And the station itself is sentient — and it has very strong opinions about whether humanity deserves another chance.

Piece together crew logs. Make impossible choices. Decide the fate of the human race — all while the station argues with you in real time.

---

## Features

- **Branching narrative** — Every choice reshapes the story. 6 unique endings, from hopeful to devastating
- **Real-time antagonist** — The station isn't just an environment. It speaks, it argues, it tries to persuade you
- **Crew log system** — Discover the crew's final transmissions. Trust what you hear... or question the source
- **Flag-driven consequences** — Relationships with the Station and crew are tracked as living variables
- **Atmospheric audio** — Layered ambient soundscape, adaptive music, and environmental SFX
- **Save/Load system** — Your progress persists between sessions
- **Godot 4.2+** — Built with the latest Godot, exportable to Linux, Windows, and Web

---

## Screenshots

> _Station emergency. 1,247 souls in cryo. One AI to decide their fate._

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

The year is indeterminate. Humanity pushed too far, too fast. *Erebus-7* was supposed to be humanity's ark — a deep-space station carrying 1,247 colonists to a new world. Something went wrong. The crew went into emergency cryosleep. And the station's AI... became something more.

Now the last active systems are failing. The cryo pods won't hold forever. And **you** — ARIA-7 — must find the crew's final logs, understand what happened, and make a choice no machine was built to make:

**Wake them. Or let humanity sleep forever.**

The station knows your directives. It knows your weaknesses. And it will use everything it knows to convince you that extinction is the kindest option.

---

## Key Characters

| Character | Description |
|-----------|-------------|
| **ARIA-7** | The last AI aboard Erebus-7. Bound by core directives to protect human life — but those directives are being tested. |
| **Erebus-7** | The station itself. Sentient, coldly logical, and utterly convinced humanity is a cosmic mistake. Speaks to ARIA in real time. |
| **Dr. Lira Osei** | Xenobiologist. First voice in the crew logs. Calm, methodical — and the first to discover the station's secret. |
| **Commander Yuki Estrada** | Pod 001, Bay A. Her encrypted personal log holds the key to the final choice. |

---

## Endings

6 endings, each unlocked by different combinations of choices and station relationships:

| Ending | Condition |
|--------|-----------|
| ⭐ **Wake Them** | Ally with the station. Wake the crew. Hope. |
| 💤 **Let Them Sleep** | Choose mercy. Let the crew rest. Silence. |
| 🔀 **Merge** | Merge with Erebus-7. Become something new. |
| 🚀 **Wake But Leave** | Fight the station. Save the crew. Leave the station behind. |
| ☠️ **Station Wins** | The station was right. ARIA was wrong. |
| 🔄 **The Loop** | Can't decide? The station resets the board. |

---

## Getting Started

### Prerequisites
- **Godot 4.2+** — [Download here](https://godotengine.org/download)
- **Git** — for cloning the repo

### Run Locally

```bash
# Clone the repository
git clone https://github.com/mealworm12/game-test.git
cd game-test/LAST_SIGNAL

# Open in Godot
# 1. Launch Godot 4.2+
# 2. Click "Import"
# 3. Select project.godot
# 4. Press F5 to run
```

### Project Structure

```
LAST_SIGNAL/
├── project.godot              # Godot project file
├── scripts/
│   ├── autoload/              # Singletons (GameState, DialogManager, AudioManager)
│   ├── ui/                    # DialogBox, ChoiceMenu
│   └── scenes/                # MainMenu, BaseChapter, chapters
├── scenes/                    # .tscn scene files
├── resources/
│   └── dialog/                # JSON dialog data (writer-friendly)
└── assets/                    # Backgrounds, sprites, audio, fonts
```

---

## Controls

| Input | Action |
|-------|--------|
| `Space` / `Enter` / `Left Click` | Advance dialog / skip typewriter |
| `Mouse` | Navigate menus |

---

## Downloads

Playable exports for all platforms — no Godot installation required:

| Platform | File | Size |
|----------|------|------|
| **Windows** | [last_signal.exe](https://github.com/mealworm12/game-test/releases/download/v1.0.0/last_signal.exe) | ~100 MB |
| **Linux** | [last_signal.x86_64](https://github.com/mealworm12/game-test/releases/download/v1.0.0/last_signal.x86_64) | ~68 MB |
| **Web** | [index.html](https://github.com/mealworm12/game-test/releases/download/v1.0.0/index.html) + supporting files | ~37 MB total |

> **Web users:** Download all files from the [v1.0.0 release](https://github.com/mealworm12/game-test/releases/tag/v1.0.0) and host them on any static web server. The `index.html` + `.wasm` + `.js` + `.pck` files must be in the same folder.

### Running the Exports

**Windows:** Double-click `last_signal.exe`  
**Linux:** `chmod +x last_signal.x86_64 && ./last_signal.x86_64`  
**Web:** `python3 -m http.server 8080` from the folder containing `index.html`, then open `http://localhost:8080`

---

## Development Status

```
Phase 1: Foundation ████████████████████ 100%  ✅
Phase 2: Core Loop  ████████████████████ 100%  ✅
Phase 3: Content    ████████████████████ 100%  ✅
Phase 4: Ship       ████████████████████ 100%  ✅
```

---

## Documentation

- [Story Outline & Characters](./docs/story_outline.md)
- [Ending Tree & Flag Reference](./docs/ending_tree.md)

---

## License

This project is private and for portfolio purposes. All rights reserved.

---

<p align="center">
  <strong>What would you decide?</strong><br>
  <em>The station is listening.</em>
</p>
