#!/usr/bin/env python3
"""Static sanity checks for the merged tree (no Godot binary needed).
Checks every .gd file for bracket balance, tab-only indentation, ASCII-only,
and unterminated strings. Checks .tscn headers + ext_resource paths.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LS = ROOT / "LAST_SIGNAL"
errors = []

def check_gd(path):
    text = path.read_text()
    depth = {"{": 0, "(": 0, "[": 0}
    close = {"}": "{", ")": "(", "]": "["}
    in_str = False
    esc = False
    prev2 = ""
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
        expanded = raw.expandtabs(1)
        if raw.startswith(" " * 4) and "\t" not in raw:
            errors.append(f"{path.name}:{lineno}: space-indented line (project uses tabs)")
            break
        if any(ord(c) > 127 for c in raw):
            # docstring em-dashes allowed only inside comments/strings; flag raw non-ASCII code lines conservatively
            stripped = raw.strip()
            if not (stripped.startswith("#") or '"' in raw):
                errors.append(f"{path.name}:{lineno}: non-ASCII outside comment/string")

gd_files = sorted(LS.rglob("*.gd"))
for f in gd_files:
    check_gd(f)

# .tscn lint: header + ext_resource res:// paths exist
for tscn in sorted(LS.rglob("*.tscn")):
    if not tscn.read_text().startswith("[gd_scene"):
        errors.append(f"{tscn.name}: missing [gd_scene] header")
    for line in tscn.read_text().splitlines():
        if line.startswith("[ext_resource"):
            import re
            m = re.search(r'path="res://([^"]+)"', line)
            if m and not (LS / m.group(1)).exists():
                errors.append(f"{tscn.name}: ext_resource missing: {m.group(1)}")

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
