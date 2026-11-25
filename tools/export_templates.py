#!/usr/bin/env python3
"""Install the export templates for the Godot version mise.toml pins: `mise run export-templates`.

Exporting needs the engine's prebuilt runtime for each platform, "export templates", which are
not part of the engine download: about 1.3 GB from the engine's release page. They go where the
editor's own installer puts them, so the editor finds them too. This downloads the release,
checks it against the published SHA-512, and unpacks it; it does nothing when they are there.

    python tools/export_templates.py          # install them if missing
    python tools/export_templates.py --check  # only say whether they are installed
"""

from __future__ import annotations

import argparse
import hashlib
import os
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path

import engine

RELEASES = "https://github.com/godotengine/godot-builds/releases/download"
TIMEOUT = 60
CHUNK = 1 << 20


def version() -> str:
    """The pinned engine's version as the templates' folder names it, such as "4.7.2.stable"."""
    done = subprocess.run(
        [engine.find(), "--version"], capture_output=True, text=True, timeout=60, check=True
    )
    # The engine prints "4.7.2.stable.official.ed1daf0bf": the first four parts.
    return ".".join(done.stdout.strip().split(".")[:4])


def templates_dir(engine_version: str) -> Path:
    """Where the editor keeps the templates for one version."""
    if sys.platform == "darwin":
        base = Path.home() / "Library" / "Application Support" / "Godot"
    elif sys.platform == "win32":
        base = Path(os.environ.get("APPDATA", str(Path.home()))) / "Godot"
    else:
        data = os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local" / "share"))
        base = Path(data) / "godot"
    return base / "export_templates" / engine_version


def installed(engine_version: str) -> bool:
    """Whether the templates for the version are where the editor looks."""
    return (templates_dir(engine_version) / "version.txt").is_file()


def fetch(url: str) -> bytes:
    """What the url holds, for a file small enough to keep in memory."""
    with urllib.request.urlopen(url, timeout=TIMEOUT) as response:
        data: bytes = response.read()
    return data


def expected_hash(tag: str, file_name: str) -> str:
    """The SHA-512 the release publishes for the file."""
    for line in fetch(f"{RELEASES}/{tag}/SHA512-SUMS.txt").decode().splitlines():
        digest, _, name = line.partition("  ")
        if name.strip() == file_name:
            return digest
    raise SystemExit(f"export_templates: {file_name} is not in the release's SHA512-SUMS.txt")


def download(url: str, target: Path) -> str:
    """Save the url to the target, and return the SHA-512 of what was saved."""
    digest = hashlib.sha512()
    done = 0
    with urllib.request.urlopen(url, timeout=TIMEOUT) as response, target.open("wb") as out:
        total = int(response.headers.get("Content-Length", 0))
        while chunk := response.read(CHUNK):
            out.write(chunk)
            digest.update(chunk)
            done += len(chunk)
            print(f"\r  {done >> 20} of {total >> 20} MB", end="", flush=True)
    print()
    return digest.hexdigest()


def install(engine_version: str) -> None:
    """Download the version's templates, check them, and unpack them into the editor's folder."""
    tag = engine_version.replace(".stable", "-stable")
    file_name = f"Godot_v{tag}_export_templates.tpz"
    wanted = expected_hash(tag, file_name)
    target = templates_dir(engine_version)
    with tempfile.TemporaryDirectory() as work:
        package = Path(work) / file_name
        print(f"Downloading {file_name}")
        if download(f"{RELEASES}/{tag}/{file_name}", package) != wanted:
            raise SystemExit("export_templates: the download does not match its SHA-512")
        print(f"Unpacking into {target}")
        target.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(package) as archive:
            for member in archive.infolist():
                relative = member.filename.removeprefix("templates/")
                if member.is_dir() or relative == member.filename:
                    continue
                path = target / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(archive.read(member))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="only report whether installed")
    arguments = parser.parse_args()
    engine_version = version()
    if installed(engine_version):
        print(f"Export templates {engine_version} are installed in {templates_dir(engine_version)}")
        return 0
    if arguments.check:
        print(f"Export templates {engine_version} are not installed: `mise run export-templates`")
        return 1
    install(engine_version)
    print(f"Export templates {engine_version} installed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
