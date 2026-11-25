#!/usr/bin/env python3
"""Run the tests with gdUnit4, and fail on anything wrong.

Imports the project once, then runs every tests/test_*.gd (or the ones named) through gdUnit4's
command-line tool in a headless engine. The run fails on a non-zero exit (gdUnit4 exits 100 for
an error, 101 for a warning such as an orphaned node), a timeout, or any script error, engine
error or warning in the output. The last line is the verdict, `VERDICT PASS` or `VERDICT FAIL`,
which the exit code matches. The reports gdUnit4 writes go to reports/.
"""

from __future__ import annotations

import argparse
import enum
import fnmatch
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import NamedTuple

import engine

ROOT = Path(__file__).resolve().parents[1]
GODOT = engine.find()
IMPORT_TIMEOUT = 240
TEST_TIMEOUT = 600
# Godot prints these for script errors, engine errors and warnings; gdUnit4 prints its own
# warnings (an orphaned node, say) after them in the same form.
BAD_OUTPUT = re.compile(r"SCRIPT ERROR|^\s*ERROR:|^\s*WARNING:", re.MULTILINE)
ANSI = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
SUMMARY = re.compile(r"^Overall Summary:.*$", re.MULTILINE)
EPILOG = """\
  python tools/run_tests.py              every test
  python tools/run_tests.py snake_game '*scene'  the tests named, or matching a glob
  python tools/run_tests.py --import-only  import the project and stop
"""


class Result(enum.StrEnum):
    """How an engine run ended. The value is what a failed run is reported as."""

    PASS = "pass"
    BAD_EXIT = "non-zero exit"
    BAD_OUTPUT = "error or warning in the output"
    TIMEOUT = "timeout"


class Outcome(NamedTuple):
    """One engine run: how it ended, how long it took, and what it printed."""

    result: Result
    seconds: float
    output: str
    exit_code: int = 0

    def describe(self) -> str:
        """The result in words, with the exit code where that is what failed."""
        if self.result is Result.BAD_EXIT:
            return f"exit {self.exit_code}"
        return self.result.value


def run(args: list[str], timeout: int) -> Outcome:
    """One bounded engine run."""
    start = time.monotonic()
    try:
        done = subprocess.run(
            [GODOT, *args], cwd=ROOT, capture_output=True, text=True, timeout=timeout, check=False
        )
    except subprocess.TimeoutExpired as expired:
        partial = expired.stdout
        text = partial.decode(errors="replace") if isinstance(partial, bytes) else partial or ""
        return Outcome(Result.TIMEOUT, time.monotonic() - start, ANSI.sub("", text))
    seconds = time.monotonic() - start
    output = ANSI.sub("", done.stdout + done.stderr)
    if done.returncode != 0:
        return Outcome(Result.BAD_EXIT, seconds, output, done.returncode)
    if BAD_OUTPUT.search(output):
        return Outcome(Result.BAD_OUTPUT, seconds, output)
    return Outcome(Result.PASS, seconds, output)


def import_project() -> Outcome:
    """Import the project, which refreshes the class cache and loads any extension. An
    extension found for the first time can make the engine exit non-zero once, so a failed
    import is tried a second time."""
    args = ["--headless", "--path", ".", "--import"]
    outcome = run(args, IMPORT_TIMEOUT)
    if outcome.result in (Result.TIMEOUT, Result.BAD_EXIT):
        outcome = run(args, IMPORT_TIMEOUT)
    # The import itself warns about what it cannot yet resolve; only its exit counts.
    if outcome.result is Result.BAD_OUTPUT:
        outcome = outcome._replace(result=Result.PASS)
    return outcome


def select_tests(names: list[str]) -> list[Path] | None:
    """The tests named (as `snake_game`, `test_snake_game` or a glob such as `snake*`), or every
    test; None, after saying so, when a name matches none."""
    tests = {path.stem.removeprefix("test_"): path for path in sorted(ROOT.glob("tests/test_*.gd"))}
    if not names:
        return list(tests.values())
    chosen: dict[str, Path] = {}
    for name in names:
        pattern = name.removeprefix("test_").removesuffix(".gd")
        hits = fnmatch.filter(tests, pattern)
        if not hits:
            print(f"no such test: {name}")
            return None
        chosen.update({hit: tests[hit] for hit in hits})
    return list(chosen.values())


def run_tests(tests: list[Path]) -> Outcome:
    """gdUnit4's command-line tool over the test files. It stops at the first failing suite
    unless told to continue (-c), and keeps only the latest report (-rc 1)."""
    args = ["--headless", "--path", ".", "--script", "res://addons/gdUnit4/bin/GdUnitCmdTool.gd"]
    # gdUnit4 warns that a headless engine delivers no key presses and stops unless told to carry
    # on; the tests send theirs through its scene runner, which needs no window.
    args += ["--ignoreHeadlessMode", "-c", "-rd", "res://reports", "-rc", "1"]
    for test in tests:
        args += ["-a", "res://" + test.relative_to(ROOT).as_posix()]
    return run(args, TEST_TIMEOUT)


def parse_options() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__.splitlines()[0],
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("tests", nargs="*", help="test names or globs, e.g. snake_game or '*scene'")
    parser.add_argument("--verbose", action="store_true", help="print every test, not only fails")
    parser.add_argument("--skip-import", action="store_true", help="the import is fresh")
    parser.add_argument("--import-only", action="store_true", help="import the project and stop")
    return parser.parse_args()


def main() -> int:
    options = parse_options()
    if options.import_only and options.tests:
        print("--import-only takes no test names")
        return 2
    tests = select_tests(options.tests)
    if tests is None:
        return 1
    if not options.skip_import:
        imported = import_project()
        if imported.result is not Result.PASS:
            print(imported.output[-3000:])
            print(f"import: {imported.describe()} after {imported.seconds:.0f} s")
            return 1
    if options.import_only:
        return 0
    tested = run_tests(tests)
    passed = tested.result is Result.PASS
    summary = SUMMARY.search(tested.output)
    if not passed or options.verbose:
        print(tested.output[-6000:].rstrip())
    if summary:
        print(summary.group(0))
    if passed:
        print(f"VERDICT PASS in {tested.seconds:.1f} s")
    else:
        print(f"VERDICT FAIL: {tested.describe()}")
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
