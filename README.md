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
| **Web** | [last_signal_web.zip](https://github.com/mealworm12/game-test/releases/download/v1.0.0/last_signal_web.zip) | ~37 MB |

> **Web users:** Download the `last_signal_web.zip` file and extract all contents to a folder. The `index.html` + `.wasm` + `.js` + `.pck` files must be in the same folder.

---

## Platform-Specific Setup

### Windows

**System Requirements:**
- Windows 10/11 (64-bit)
- 4 GB RAM minimum
- DirectX 11 compatible GPU

**Installation:**
1. Download `last_signal.exe` from the [v1.0.0 release](https://github.com/mealworm12/game-test/releases/tag/v1.0.0)
2. Create a folder for the game (e.g., `C:\Games\LastSignal\`)
3. Move `last_signal.exe` into that folder
4. Double-click `last_signal.exe` to launch

**Troubleshooting:**
- **Game won't start:** Right-click `last_signal.exe` → Properties → Check "Unblock" at the bottom → Apply
- **Black screen:** Update your graphics drivers. The game requires DirectX 11 support
- **Audio issues:** Check Windows sound settings. The game uses your default audio output device
- **Save data location:** `C:\Users\<YourName>\AppData\Roaming\Godot\app_userdata\Last Signal\`

---

### Linux

**System Requirements:**
- Linux 64-bit (Ubuntu 20.04+, Fedora 33+, or equivalent)
- 4 GB RAM minimum
- OpenGL 3.3 / Vulkan compatible GPU

**Installation:**
```bash
# 1. Download the Linux export
wget https://github.com/mealworm12/game-test/releases/download/v1.0.0/last_signal.x86_64

# 2. Create a game directory
mkdir -p ~/Games/LastSignal
mv last_signal.x86_64 ~/Games/LastSignal/
cd ~/Games/LastSignal/

# 3. Make executable
chmod +x last_signal.x86_64

# 4. Run the game
./last_signal.x86_64
```

**Alternative (Steam/Flatpak friendly):**
```bash
# Create a desktop entry
cat > ~/.local/share/applications/last-signal.desktop << 'EOF'
[Desktop Entry]
Name=Last Signal
Exec=/home/YOUR_USERNAME/Games/LastSignal/last_signal.x86_64
Type=Application
Icon=application-x-executable
Categories=Game;
EOF
```

**Troubleshooting:**
- **Permission denied:** Run `chmod +x last_signal.x86_64`
- **Missing libraries (Ubuntu/Debian):** `sudo apt install libgl1-mesa-glx libxcursor1 libxrandr2 libxinerama1 libxi6`
- **No sound:** Install PulseAudio or PipeWire. The game requires a working audio server
- **Save data location:** `~/.local/share/godot/app_userdata/Last Signal/`

---

### Web (Browser)

**System Requirements:**
- Modern browser (Chrome 90+, Firefox 88+, Edge 90+, Safari 15+)
- WebGL 2.0 support
- 4 GB RAM recommended
- Stable internet connection for initial load

**Option A: Local Testing**
```bash
# 1. Download and extract the web export
wget https://github.com/mealworm12/game-test/releases/download/v1.0.0/last_signal_web.zip
unzip last_signal_web.zip
cd last_signal_web/

# 2. Start a local web server (Python 3)
python3 -m http.server 8080

# 3. Open your browser to:
# http://localhost:8080
```

**Option B: Self-Hosted (Any Static Host)**
1. Download `last_signal_web.zip` from the [v1.0.0 release](https://github.com/mealworm12/game-test/releases/tag/v1.0.0)
2. Extract all files to a folder
3. Upload **all files** to your web host (GitHub Pages, Netlify, Vercel, itch.io, etc.)
4. Ensure all files are in the same directory:
   - `index.html`
   - `last_signal.html` (or similar `.js` file)
   - `last_signal.wasm`
   - `last_signal.pck`

**Required HTTP Headers:**
Your server must serve these headers for WebAssembly to work:
```
Content-Type: application/wasm  (for .wasm files)
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

**GitHub Pages Setup:**
1. Create a new repository or use an existing one
2. Upload all web export files to the `main` branch
3. Go to Settings → Pages → Select branch: `main` / root
4. Wait ~2 minutes for deployment
5. Your game will be live at `https://<username>.github.io/<repo>/`

**itch.io Upload:**
1. Create a new project on [itch.io](https://itch.io)
2. Click "Upload new file"
3. Select "HTML" as the file type
4. Upload the **entire extracted folder** (or zip it and upload)
5. Set "Kind of project" to **HTML**
6. Check "This file will be played in the browser"
7. Save and publish

**Troubleshooting:**
- **White screen / infinite loading:** Check browser console (F12). Likely missing `.wasm` or `.pck` file
- **"WebAssembly.instantiate failed":** Your server isn't serving correct MIME types. Add the headers above
- **Audio doesn't work:** Browsers block autoplay. Click anywhere on the page first to enable audio context
- **Controls don't respond:** Click the game canvas to give it focus

---

### Running from Source (Godot)

Want to modify the game or explore the project?

**Prerequisites:**
- Godot 4.6+ — [Download here](https://godotengine.org/download)
- Git

**Setup:**
```bash
# Clone the repository
git clone https://github.com/mealworm12/game-test.git
cd game-test/LAST_SIGNAL

# Open in Godot:
# 1. Launch Godot 4.6+
# 2. Click "Import"
# 3. Navigate to and select project.godot
# 4. Click "Import & Edit"
# 5. Press F5 to run the game
```

**Export Your Own Build:**
1. Open project in Godot
2. Go to Project → Export
3. Select your target platform (Linux/X11, Windows Desktop, Web)
4. Click "Export Project"
5. Choose destination folder and filename

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
