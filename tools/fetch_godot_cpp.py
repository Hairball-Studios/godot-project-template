#!/usr/bin/env python3
"""Download godot-cpp, the C++ bindings the game's classes in native/ build against.

The commit is $GODOT_CPP_REF (mise.toml). The checkout lands in native/godot-cpp, which git
ignores; nothing happens when it is already at that commit. When mise.toml names another
commit, delete the folder and run this again.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "native" / "godot-cpp"
URL = "https://github.com/godotengine/godot-cpp"
TIMEOUT = 300


def git(*words: str) -> int:
    """One git command in the checkout's folder; its exit code."""
    return subprocess.run(
        ["git", "-C", str(TARGET), *words], check=False, timeout=TIMEOUT
    ).returncode


def checked_out() -> str:
    """The commit the checkout is at, or empty where there is no checkout."""
    if not (TARGET / "SConstruct").exists():
        return ""
    done = subprocess.run(
        ["git", "-C", str(TARGET), "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
        check=False,
        timeout=TIMEOUT,
    )
    return done.stdout.strip()


def main() -> int:
    ref = os.environ.get("GODOT_CPP_REF")
    if not ref:
        print("fetch_godot_cpp: GODOT_CPP_REF is not set: run it through `mise run`")
        return 1
    have = checked_out()
    if have == ref:
        print(f"fetch_godot_cpp: {TARGET.relative_to(ROOT)} is already at {ref[:10]}")
        return 0
    if have or TARGET.exists():
        print(f"fetch_godot_cpp: {TARGET.relative_to(ROOT)} is at '{have[:10]}', not {ref[:10]}:")
        print("delete the folder and run this again")
        return 1
    TARGET.mkdir(parents=True)
    steps = (["init", "--quiet"], ["fetch", "--depth", "1", URL, ref], ["checkout", "FETCH_HEAD"])
    for step in steps:
        print("git " + " ".join(step))
        if git(*step) != 0:
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
