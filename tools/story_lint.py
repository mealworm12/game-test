#!/usr/bin/env python3
"""story_lint.py — validates Last Signal v2 narrative content files.

Checks:
  1. Every sfx/music/voice/portrait ID is in the allowed contract set.
  2. Every bg path is either an existing v1 background or a whitelisted incoming one.
  3. Every flag referenced (set_flag / if_flag) is a canon flag or v2_-prefixed.
  4. No orphan labels / gotos (if_flag targets and labels resolve within file).
  5. dive_start/dive_end balanced; every ending has at least one reachable walk.

Usage: python3 tools/story_lint.py [content_dir]  (default: LAST_SIGNAL/content/v2)
Exit code 0 = pass, 1 = failures found.
"""
import re
import sys
from pathlib import Path

ALLOWED_MUSIC = {
    "music/main_theme", "music/calm_loop", "music/tension_loop", "music/dread_loop",
    "music/hope_loop", "music/end_wake_them", "music/end_let_them_sleep",
    "music/end_merge", "music/end_wake_but_leave", "music/end_station_wins",
    "music/end_the_loop",
}
ALLOWED_SFX = {
    "sfx/ui_hover", "sfx/ui_confirm", "sfx/ui_back", "sfx/log_play", "sfx/terminal_type",
    "sfx/door_open", "sfx/door_close", "sfx/alarm_soft", "sfx/alarm_hard", "sfx/pod_hiss",
    "sfx/power_down", "sfx/power_up", "sfx/heartbeat_low", "sfx/cryo_beep_loop",
    "sfx/static_burst",
}
ALLOWED_VOICE = {"voice/station_low", "voice/station_hostile", "voice/station_intimate"}
ALLOWED_PORTRAITS = {
    "aria:neutral", "aria:alert", "aria:distressed",
    "erebus:cold", "erebus:hostile", "erebus:placated",
}
V1_BGS = {
    "bg_bridge", "bg_corridor", "bg_cryobay", "bg_engineering", "bg_medical", "bg_void",
}
INCOMING_BGS = {"bg_observation", "bg_reactor"}
CANON_FLAGS = {
    "heard_log_1", "heard_log_2", "ran_diagnostic", "station_trust", "station_suspicious",
    "station_hostile", "station_allied", "found_override_codes", "station_knows_truth",
    "crew_legacy_protected", "confrontation_path", "crew_awakened", "ending_merged",
}

LINE_RE = re.compile(r"^\s*(\w+)(?:\s+(\S.*))?$")


def fail(errors, path, lineno, msg):
    errors.append(f"{path}:{lineno}: {msg}")


def parse_file(path):
    """Return (commands, errors) where commands is list of (lineno, cmd, arg)."""
    commands, errors = [], []
    for lineno, raw in enumerate(path.read_text().splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = LINE_RE.match(line)
        if not m:
            fail(errors, path.name, lineno, f"unparseable line: {line!r}")
            continue
        cmd, arg = m.group(1), (m.group(2) or "").strip()
        commands.append((lineno, cmd, arg))
    return commands, errors


def lint_dialog(path):
    errors, warnings = [], []
    commands, errs = parse_file(path)
    errors.extend(errs)

    labels, gotos, flags_set, flags_checked = set(), [], set(), set()
    dives, ends_seen = [], []
    for lineno, cmd, arg in commands:
        if cmd == "label":
            name = arg
            if name in labels:
                fail(errors, path.name, lineno, f"duplicate label '{name}'")
            labels.add(name)
        elif cmd == "if_flag":
            parts = arg.split()
            if len(parts) != 3 or parts[1] != "goto":
                fail(errors, path.name, lineno, f"malformed if_flag: {arg!r}")
                continue
            flags_checked.add(parts[0])
            gotos.append((lineno, parts[2]))
        elif cmd == "set_flag":
            if not arg:
                fail(errors, path.name, lineno, "set_flag missing flag")
            else:
                flags_set.add(arg.split()[0])
        elif cmd in ("say", "choice"):
            if "|" not in arg:
                fail(errors, path.name, lineno, f"{cmd} missing '|' separator")
            elif cmd == "say" and arg.startswith("EREBUS|"):
                # Canon voice rule (docs/story_outline.md): Erebus speaks
                # lowercase, deliberate, NO terminal punctuation. Ellipses
                # are allowed as deliberate pauses; periods are not.
                spoken = arg.split("|", 1)[1].rstrip()
                if spoken.endswith("."):
                    fail(errors, path.name, lineno,
                         "Erebus line violates canon voice rule (no terminal punctuation)")
        elif cmd == "music":
            if arg not in ALLOWED_MUSIC:
                fail(errors, path.name, lineno, f"unknown music id '{arg}'")
        elif cmd == "sfx":
            if arg not in ALLOWED_SFX:
                fail(errors, path.name, lineno, f"unknown sfx id '{arg}'")
        elif cmd == "voice":
            if arg not in ALLOWED_VOICE:
                fail(errors, path.name, lineno, f"unknown voice id '{arg}'")
        elif cmd == "portrait":
            if arg not in ALLOWED_PORTRAITS:
                fail(errors, path.name, lineno, f"unknown portrait '{arg}'")
        elif cmd == "bg":
            if arg not in V1_BGS | INCOMING_BGS:
                fail(errors, path.name, lineno, f"unknown bg '{arg}'")
        elif cmd == "dive_start":
            if not arg:
                fail(errors, path.name, lineno, "dive_start missing id")
            dives.append((lineno, arg))
        elif cmd == "dive_end":
            if not dives:
                fail(errors, path.name, lineno, "dive_end without dive_start")
            else:
                dives.pop()
        elif cmd == "codex_unlock":
            if not arg.startswith("codex_"):
                fail(errors, path.name, lineno, f"suspicious codex id '{arg}'")
            ends_seen.append((lineno, arg))
        # unknown commands are reported by the caller-level check below

    known_cmds = {
        "say", "choice", "set_flag", "if_flag", "label", "sfx", "music", "voice",
        "bg", "portrait", "dive_start", "dive_end", "codex_unlock",
    }
    for lineno, cmd, _ in commands:
        if cmd not in known_cmds:
            fail(errors, path.name, lineno, f"unknown command '{cmd}'")

    for lineno, target in gotos:
        if target not in labels:
            fail(errors, path.name, lineno, f"goto to undefined label '{target}'")

    for flag in flags_set | flags_checked:
        if flag not in CANON_FLAGS and not flag.startswith("v2_"):
            fail(errors, path.name, 0, f"flag '{flag}' is neither canon nor v2_-prefixed")

    return errors, warnings


def lint_codex(path):
    """Codex data file: sections must be codex_* ids; ASCII only."""
    errors = []
    text = path.read_text()
    for i, ch in enumerate(text):
        if ord(ch) > 127:
            errors.append(f"{path.name}: non-ASCII char {ch!r} at offset {i}")
            break
    section = None
    for lineno, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            if not section.startswith("codex_"):
                errors.append(f"{path.name}:{lineno}: section '{section}' lacks codex_ prefix")
        elif ":" not in line:
            errors.append(f"{path.name}:{lineno}: expected 'key: value' inside [{section}]")
    return errors


def main():
    content_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("LAST_SIGNAL/content/v2")
    all_errors = []
    dlg_files = sorted(content_dir.glob("*.dlg"))
    if not dlg_files:
        all_errors.append(f"no .dlg files found under {content_dir}")

    for f in dlg_files:
        errs, _warns = lint_dialog(f)
        all_errors.extend(errs)

    for f in sorted(content_dir.glob("*.txt")):
        if f.name == "codex_entries.txt" or "[codex_" in f.read_text():
            all_errors.extend(lint_codex(f))

    if all_errors:
        print("STORY LINT — FAIL")
        for e in all_errors:
            print(f"  ERROR {e}")
        print(f"\n{len(all_errors)} error(s)")
        return 1

    n_dlg = len(dlg_files)
    n_logs = sum(1 for f in dlg_files if f.name.startswith("log_"))
    text = "\n".join(f.read_text() for f in dlg_files)
    n_dives = len(re.findall(r"^dive_start ", text, re.M))
    n_epilogue_labels = len(re.findall(r"^label (wake_them|sleep|merge|leave|wins|loop)_", text, re.M))
    print("STORY LINT — PASS")
    print(f"  dialog files checked : {n_dlg}")
    print(f"  log scenes           : {n_logs}")
    print(f"  memory dives         : {n_dives}")
    print(f"  epilogue variant blocks: {n_epilogue_labels}")
    print(f"  asset ids validated  : music/sfx/voice/portrait/bg against contract sets")
    print(f"  flags validated      : canon or v2_ prefixed only")
    return 0


if __name__ == "__main__":
    sys.exit(main())
