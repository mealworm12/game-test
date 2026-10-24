#!/usr/bin/env python3
"""Static sanity checks for the merged tree (no Godot binary needed).
Checks every .gd file for bracket balance, tab-only indentation, ASCII-only,
and unterminated strings. Checks .tscn headers + ext_resource paths, script
attachment, and Godot 3 node types that no longer exist in Godot 4.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LS = ROOT / "LAST_SIGNAL"
errors = []

# Node types that were renamed/removed in Godot 4. A scene that still uses one
# gets a placeholder node at runtime, so the UI silently loses its layout.
GODOT3_NODE_TYPES = {
    "VBox": "VBoxContainer",
    "HBox": "HBoxContainer",
    "Spatial": "Node3D",
    "KinematicBody": "CharacterBody3D",
    "KinematicBody2D": "CharacterBody2D",
    "RigidBody": "RigidBody3D",
    "StaticBody": "StaticBody3D",
    "Position2D": "Marker2D",
    "Position3D": "Marker3D",
}


def check_gd(path):
    text = path.read_text()
    depth = {"{": 0, "(": 0, "[": 0}
    close = {"}": "{", ")": "(", "]": "["}
    in_str = False
    esc = False
    for i, ch in enumerate(text):
        if ch == "\n":
            in_str = False
            continue
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
        elif ch in depth:
            depth[ch] += 1
        elif ch in close:
            depth[close[ch]] -= 1
            if depth[close[ch]] < 0:
                errors.append(f"{path.name}: unmatched '{ch}' at offset {i}")
                return
    if in_str:
        errors.append(f"{path.name}: unterminated string literal")
    for k, v in depth.items():
        if v != 0:
            errors.append(f"{path.name}: unbalanced '{k}' (net {v:+d})")
    for lineno, raw in enumerate(text.splitlines(), 1):
        if "/**" in raw:
            errors.append(f"{path.name}:{lineno}: GDScript has no /** */ comments (use #)")
            break
        expanded = raw.expandtabs(1)
        if raw.startswith(" " * 4) and "\t" not in raw:
            errors.append(f"{path.name}:{lineno}: space-indented line (project uses tabs)")
            break
        if any(ord(c) > 127 for c in raw):
            stripped = raw.strip()
            if not (stripped.startswith("#") or '"' in raw):
                errors.append(f"{path.name}:{lineno}: non-ASCII outside comment/string")


gd_files = sorted(LS.rglob("*.gd"))
for f in gd_files:
    check_gd(f)

# .tscn lint: header, ext_resource paths, attached scripts, Godot 3 types
for tscn in sorted(LS.rglob("*.tscn")):
    text = tscn.read_text()
    if not text.startswith("[gd_scene"):
        errors.append(f"{tscn.name}: missing [gd_scene] header")

    script_ids = []
    for line in text.splitlines():
        if line.startswith("[ext_resource"):
            m = re.search(r'path="res://([^"]+)"', line)
            if m and not (LS / m.group(1)).exists():
                errors.append(f"{tscn.name}: ext_resource missing: {m.group(1)}")
            sm = re.search(r'type="Script".*id="([^"]+)"', line)
            if sm:
                script_ids.append(sm.group(1))

    attached = set(re.findall(r"^script = ExtResource\(\"([^\"]+)\"\)", text, re.M))
    for sid in script_ids:
        if sid not in attached:
            errors.append(
                f"{tscn.name}: Script ext_resource '{sid}' is declared but never "
                f"attached to a node (scene will run without its logic)"
            )

    for node_type in re.findall(r'^\[node [^\]]*type="([^"]+)"', text, re.M):
        if node_type in GODOT3_NODE_TYPES:
            errors.append(
                f"{tscn.name}: node type '{node_type}' is Godot 3; "
                f"use '{GODOT3_NODE_TYPES[node_type]}'"
            )

print(f"GD files checked : {len(gd_files)}")
tscn_count = len(list(LS.rglob('*.tscn')))
print(f"tscn checked     : {tscn_count}")
if errors:
    print("STATIC CHECK — FAIL")
    for e in errors:
        print(f"  ERROR {e}")
else:
    print("STATIC CHECK — PASS")
sys.exit(1 if errors else 0)
