#!/usr/bin/env python3
"""Turn on the commit hook in .githooks: the second step of `mise run setup`.

A folder that is not a git repository (a downloaded ZIP, say) has no hooks to turn on, and that
must not stop the rest of the setup: this says so and succeeds. Run `mise run setup` again after
`git init` to turn the hook on.

    python tools/git_hook.py
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def git(*words: str) -> int:
    """One git command in the project's folder; its exit code, or 1 where git is not installed."""
    try:
        return subprocess.run(
            ["git", *words], cwd=ROOT, capture_output=True, timeout=60, check=False
        ).returncode
    except OSError, subprocess.TimeoutExpired:
        return 1


def main() -> int:
    if git("rev-parse", "--is-inside-work-tree") != 0:
        print("git_hook: not a git repository, so no commit hook: run setup again after `git init`")
        return 0
    if git("config", "core.hooksPath", ".githooks") != 0:
        print("git_hook: could not set core.hooksPath")
        return 1
    print("git_hook: commits now run .githooks/pre-commit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
