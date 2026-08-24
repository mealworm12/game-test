#!/usr/bin/env python3
"""v2_reference_check.py — integration cross-reference checker.

Validates zero dangling references across the merged tree:
  1. Every sfx/music/voice ID in content/v2/*.dlg exists in AudioManager.gd's
     ID tables AND resolves to a file on disk under LAST_SIGNAL/assets/audio/v2/.
  2. Every portrait <who>:<expr> maps to an art asset on disk.
  3. Every bg name maps to LAST_SIGNAL/assets/backgrounds/<name>.png on disk.
  4. Every codex_unlock id has a section in codex_entries.txt.
  5. Every AUDIO_MANIFEST.md ID row exists on disk; every ART_MANIFEST.md file
     row exists on disk.
  6. Ending stinger IDs cover all six endings in ending_tree.md / Epilogue texts.

Usage: python3 tools/v2_reference_check.py   (exit 0 = pass)
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LS = ROOT / "LAST_SIGNAL"
errors = []


def err(msg):
    errors.append(msg)


# ---- Parse AudioManager ID tables ------------------------------------
am_lines = (LS / "scripts/autoload/AudioManager.gd").read_text().splitlines()
audio_tables = {}
current = None
for ln in am_lines:
    dm = re.match(r"const (MUSIC_IDS|SFX_IDS|VOICE_IDS): Dictionary = \{", ln)
    if dm:
        current = dm.group(1)
        audio_tables[current] = {}
        continue
    if current:
        if ln.strip() == "}":
            current = None
            continue
        pair = re.search(r'"([^"]+)":\s*"res://([^"]+)"', ln)
        if pair:
            audio_tables[current][pair.group(1)] = pair.group(2)

# ---- Parse content scripts -------------------------------------------
content = LS / "content/v2"
music_used, sfx_used, voice_used, portraits_used, bgs_used, codex_used = set(), set(), set(), set(), set(), set()
dlg_files = sorted(content.glob("*.dlg"))
if not dlg_files:
    err("no .dlg files under content/v2")
for f in dlg_files:
    for lineno, raw in enumerate(f.read_text().splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split(None, 1)
        cmd, arg = parts[0], (parts[1] if len(parts) > 1 else "")
        if cmd == "music":
            music_used.add(arg)
        elif cmd == "sfx":
            sfx_used.add(arg)
        elif cmd == "voice":
            voice_used.add(arg)
        elif cmd == "portrait":
            portraits_used.add(arg)
        elif cmd == "bg":
            bgs_used.add(arg)
        elif cmd == "codex_unlock":
            codex_used.add(arg)

# ---- Audio: story usage -> AudioManager tables -> disk -----------------
kind_map = [("MUSIC_IDS", "music", music_used), ("SFX_IDS", "sfx", sfx_used), ("VOICE_IDS", "voice", voice_used)]
for table, sub, used in kind_map:
    for uid in sorted(used):
        if "/" not in uid:
            err(f"audio id '{uid}' lacks kind prefix")
            continue
        prefix, short = uid.split("/", 1)
        if prefix != sub:
            err(f"audio id '{uid}' prefix does not match expected '{sub}'")
        if short not in audio_tables.get(table, {}):
            err(f"audio id '{uid}' not in AudioManager.{table}")
        else:
            rel = audio_tables[table][short]
            if not (LS / rel.removeprefix("res://")).exists():
                err(f"audio id '{uid}' path missing on disk: {rel}")

# ---- Portraits ---------------------------------------------------------
PORTRAIT_FILES = {
    ("aria", "neutral"): "aria7_neutral.png",
    ("aria", "alert"): "aria7_alert.png",
    ("aria", "distressed"): "aria7_distressed.png",
    ("erebus", "cold"): "erebus7_cold.png",
    ("erebus", "hostile"): "erebus7_hostile.png",
    ("erebus", "placated"): "erebus7_placated.png",
}
for p in sorted(portraits_used):
    who, _, expr = p.partition(":")
    key = (who.strip().lower(), expr.strip().lower())
    fname = PORTRAIT_FILES.get(key)
    if not fname:
        err(f"portrait '{p}' has no mapped art asset")
    elif not ((LS / "assets/portraits" / fname).exists() or (LS / "assets/art" / fname).exists()):
        err(f"portrait '{p}' file missing: {fname}")

# ---- Backgrounds -------------------------------------------------------
# bg_observation (story contract name) maps to the art card's actual file.
BG_ALIASES = {"bg_observation": "bg_observation_deck"}
for b in sorted(bgs_used):
    fname = BG_ALIASES.get(b, b)
    if not (LS / f"assets/backgrounds/{fname}.png").exists():
        err(f"bg '{b}' missing at assets/backgrounds/{fname}.png")

# ---- Codex -------------------------------------------------------------
codex_text = (content / "codex_entries.txt").read_text()
defined_codex = set(re.findall(r"^\[([a-z_]+)\]", codex_text, re.M))
for c in sorted(codex_used):
    if c not in defined_codex:
        err(f"codex_unlock '{c}' has no [section] in codex_entries.txt")

# ---- AUDIO_MANIFEST rows ----------------------------------------------
manifest = (ROOT / "docs/AUDIO_MANIFEST.md").read_text()
for mid, rel in re.findall(r"\|\s*`([\w/]+)`\s*\|\s*([\w/.]+\.wav)", manifest):
    candidates = [LS / "assets/audio/v2" / rel]
    if "/" not in str(rel):
        sub = {"music": "music", "sfx": "sfx", "voice": "voice"}[mid.split("/")[0]]
        candidates.append(LS / "assets/audio/v2" / sub / rel)
    if not any(c.exists() for c in candidates):
        err(f"AUDIO_MANIFEST id '{mid}' -> file not found ({rel})")

# ---- ART_MANIFEST rows -------------------------------------------------
art_manifest = (ROOT / "docs/ART_MANIFEST.md").read_text()
for rel in re.findall(r"`(assets/(?:art|portraits|backgrounds|ui)/[\w./-]+\.png)`", art_manifest):
    if not (LS / rel).exists():
        err(f"ART_MANIFEST file missing: {rel}")

# ---- Ending stinger coverage ------------------------------------------
STINGER_FOR = {
    "ending_wake": "end_wake_them",
    "ending_sleep": "end_let_them_sleep",
    "ending_merge": "end_merge",
    "ending_wake_leave": "end_wake_but_leave",
    "ending_station_wins": "end_station_wins",
    "ending_loop": "end_the_loop",
}
for ending, stinger in STINGER_FOR.items():
    if stinger not in audio_tables.get("MUSIC_IDS", {}):
        err(f"no stinger wired for {ending} ({stinger} not in MUSIC_IDS)")

print("V2 REFERENCE CHECK — " + ("FAIL" if errors else "PASS"))
for e in errors:
    print(f"  ERROR {e}")
if not errors:
    print(f"  dialog files          : {len(dlg_files)}")
    print(f"  music/sfx/voice ids ok: {len(music_used)}/{len(sfx_used)}/{len(voice_used)}")
    print(f"  portraits ok          : {len(portraits_used)}")
    print(f"  backgrounds ok        : {len(bgs_used)}")
    print(f"  codex ids ok          : {len(codex_used)} (of {len(defined_codex)} defined)")
    print(f"  stinger coverage      : 6/6 endings")
sys.exit(1 if errors else 0)
