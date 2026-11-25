#!/usr/bin/env python3
"""Lay out the project's own C++ (native/src) with clang-format, or check that it is laid out.

The `format` and `format-check` mise tasks run this, which keeps the tasks free of shell globs
that differ between the shells mise uses on macOS and on Windows.

    python tools/clang_format.py           # lay out the files
    python tools/clang_format.py --check   # change nothing; fail if any is not laid out
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "native" / "src"


def own_files(*patterns: str) -> list[str]:
    """The project's C++ files that match, as paths from the project's root."""
    found = {path for pattern in patterns for path in SOURCES.rglob(pattern)}
    return sorted(str(path.relative_to(ROOT)) for path in found)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="change nothing; fail if any differs")
    options = parser.parse_args()
    files = own_files("*.cpp", "*.h")
    if not files:
        print("clang_format: the project has no C++ file")
        return 0
    mode = ["--dry-run", "--Werror"] if options.check else ["-i"]
    return subprocess.run(["clang-format", *mode, *files], cwd=ROOT, check=False).returncode


if __name__ == "__main__":
    sys.exit(main())
