#!/usr/bin/env python3
"""Run clang-tidy over the project's own C++ (native/src) and fail on any report.

The checks are `.clang-tidy`'s. The build (`mise run build`) writes the compilation database,
native/compile_commands.json, which holds each file's flags and include folders; this adds only
what clang-tidy needs to find the compiler's and the system's headers, which the conda package
does not bring.

    python tools/clang_tidy.py    # check every file; exit 0 only with no report
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

import clang_format

ROOT = Path(__file__).resolve().parents[1]
DATABASE = ROOT / "native"
TIMEOUT = 600


def ask(*words: str) -> str:
    """What a program prints for its arguments, or empty where it is not there."""
    try:
        done = subprocess.run(words, capture_output=True, text=True, timeout=60, check=False)
    except OSError, subprocess.TimeoutExpired:
        return ""
    return done.stdout.strip()


def header_flags() -> list[str]:
    """The flags that point clang-tidy at the installed compiler's headers and, on macOS, at the
    system's SDK.

    Not on Windows: the conda package brings no clang++ there, so the one asked would be
    another installed LLVM's (C:\\Program Files\\LLVM, say), whose headers the pinned
    clang-tidy may not parse. The pinned clang-tidy finds its own headers there."""
    flags: list[str] = []
    resource_dir = "" if sys.platform == "win32" else ask("clang++", "-print-resource-dir")
    if resource_dir:
        flags += [f"--extra-arg=-resource-dir={resource_dir}"]
    if sys.platform == "darwin":
        sdk = ask("xcrun", "--show-sdk-path")
        if sdk:
            flags += ["--extra-arg=-isysroot", f"--extra-arg={sdk}"]
    return flags


def main() -> int:
    files = clang_format.own_files("*.cpp")
    if not files:
        print("clang_tidy: the project has no C++ file")
        return 0
    if not (DATABASE / "compile_commands.json").exists():
        print("clang_tidy: no native/compile_commands.json: run `mise run build` first")
        return 1
    command = ["clang-tidy", "-p", str(DATABASE), "--quiet", *header_flags(), *files]
    # Windows starts a bare program name only as a .exe, so it would pass over mise's
    # clang-tidy.cmd for another clang-tidy.exe on the path: the full path is the pinned one.
    command[0] = shutil.which("clang-tidy") or "clang-tidy"
    try:
        return subprocess.run(command, cwd=ROOT, timeout=TIMEOUT, check=False).returncode
    except FileNotFoundError:
        print("clang_tidy: clang-tidy is not on the path: run it as `mise exec -- python ...`")
        return 1


if __name__ == "__main__":
    sys.exit(main())
