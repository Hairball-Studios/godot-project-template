#!/usr/bin/env python3
"""Run the Godot version mise.toml pins, with the arguments given.

A `godot` of another version can come first on the path (an installed editor, say), and the
tests and checks must run on the pinned one. `find()` is what the other tools import; run as a
program this passes its arguments to the engine:

    python tools/engine.py --headless --path . --script res://tools/load_all_scripts.gd
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def ask_mise(*words: str) -> str:
    """What `mise` prints for its arguments, or empty where it fails or is not there."""
    try:
        asked = subprocess.run(
            ["mise", *words],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
    except OSError, subprocess.TimeoutExpired:
        return ""
    return asked.stdout.strip() if asked.returncode == 0 else ""


def find() -> str:
    """The engine's command: $GODOT, else the one mise pins (`mise which godot`), else the
    engine file in the pinned install's folder, else the first `godot` on the path.

    On Windows and Linux mise's godot install provides no `godot`, only the release's own file
    names (`Godot_v<version>_win64.exe` and `..._win64_console.exe`, `..._linux.x86_64`), so
    `mise which godot` fails there. On Windows the console build is the one taken: it prints
    to the terminal that runs it, which headless runs need."""
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    pinned = ask_mise("which", "godot")
    if pinned:
        return pinned
    install = ask_mise("where", "godot")
    if install:
        pattern = "Godot_*_console.exe" if sys.platform == "win32" else "Godot_*"
        engines = sorted(path for path in Path(install).glob(pattern) if path.is_file())
        if engines:
            return str(engines[0])
    return shutil.which("godot") or "godot"


def main() -> int:
    return subprocess.run([find(), *sys.argv[1:]], cwd=ROOT, check=False).returncode


if __name__ == "__main__":
    sys.exit(main())
