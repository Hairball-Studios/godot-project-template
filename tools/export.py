#!/usr/bin/env python3
"""Export the game as a release build for this computer's platform: `mise run export`.

Builds the C++ classes as a release library, imports the project, and runs the engine's export
for the preset in export_presets.cfg that matches the platform. The result lands in build/. A
platform's export needs that platform's C++ library, which only a computer of that platform builds
here, so each platform exports on its own computer.

    python tools/export.py
"""

from __future__ import annotations

import configparser
import subprocess
import sys
from pathlib import Path

import engine
import export_templates

ROOT = Path(__file__).resolve().parents[1]
TIMEOUT = 1800
# The `platform` each preset in export_presets.cfg carries, by the Python name of the platform.
PLATFORMS = {"darwin": "macOS", "win32": "Windows Desktop", "linux": "Linux"}


def preset() -> tuple[str, Path]:
    """The name and output file of this platform's preset in export_presets.cfg."""
    platform = PLATFORMS.get(sys.platform)
    if platform is None:
        raise SystemExit(f"export: no preset for the platform {sys.platform}")
    presets = configparser.ConfigParser(interpolation=None, strict=False)
    presets.read(ROOT / "export_presets.cfg", encoding="utf-8")
    for section in presets.sections():
        is_preset = section.startswith("preset.") and not section.endswith(".options")
        if is_preset and presets[section]["platform"].strip('"') == platform:
            name = presets[section]["name"].strip('"')
            output = presets[section]["export_path"].strip('"')
            return name, ROOT / output
    raise SystemExit(f"export: export_presets.cfg has no preset for {platform}")


def run(command: list[str], what: str) -> None:
    """One step, announced as `what`; a step that fails stops the export."""
    print(f"export: {what}")
    if subprocess.run(command, cwd=ROOT, timeout=TIMEOUT, check=False).returncode != 0:
        raise SystemExit(f"export: {what} failed")


def main() -> int:
    name, output = preset()
    if not export_templates.installed(export_templates.version()):
        print("export: the export templates are not installed: run `mise run export-templates`")
        return 1
    # macOS ships one library for Intel and Apple silicon; the engine's export wants that.
    arch = ["arch=universal"] if sys.platform == "darwin" else []
    run(["scons", "-C", "native", "target=template_release", *arch], "building the release library")
    run([engine.find(), "--headless", "--path", ".", "--import"], "importing the project")
    output.parent.mkdir(parents=True, exist_ok=True)
    run(
        [engine.find(), "--headless", "--path", ".", "--export-release", name, str(output)],
        f"exporting {name}",
    )
    print(f"export: wrote {output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
