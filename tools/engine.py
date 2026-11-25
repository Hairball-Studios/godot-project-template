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


def find() -> str:
    """The engine's command: $GODOT, else the one mise pins (`mise which godot`), else the first
    `godot` on the path."""
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    try:
        asked = subprocess.run(
            ["mise", "which", "godot"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
    except OSError, subprocess.TimeoutExpired:
        asked = None
    if asked is not None and asked.returncode == 0 and asked.stdout.strip():
        return asked.stdout.strip()
    return shutil.which("godot") or "godot"


def main() -> int:
    return subprocess.run([find(), *sys.argv[1:]], cwd=ROOT, check=False).returncode


if __name__ == "__main__":
    sys.exit(main())
