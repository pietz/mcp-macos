#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import pathlib
import shutil
import subprocess
import sys
import tomllib

ROOT = pathlib.Path(__file__).resolve().parent.parent
PYPROJECT = ROOT / "pyproject.toml"
DIST_DIR = ROOT / "dist"


class ReleaseError(RuntimeError):
    pass


def _load_version_from_text(content: str) -> str:
    data = tomllib.loads(content)
    try:
        return data["project"]["version"]
    except KeyError as exc:  # pragma: no cover - defensive
        raise ReleaseError("Version not found in pyproject.toml") from exc


def _current_version() -> str:
    return _load_version_from_text(PYPROJECT.read_text(encoding="utf-8"))


def _previous_version() -> str | None:
    try:
        result = subprocess.run(
            ["git", "show", "HEAD^:pyproject.toml"],
            cwd=ROOT,
            check=True,
            text=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError:
        return None

    try:
        return _load_version_from_text(result.stdout)
    except ReleaseError:
        return None


def _write_outputs(outputs: dict[str, str]) -> None:
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return
    with open(output_path, "a", encoding="utf-8") as handle:
        for key, value in outputs.items():
            handle.write(f"{key}={value}\n")


def cmd_detect() -> None:
    current = _current_version()
    previous = _previous_version()
    release_needed = previous != current or previous is None

    print(f"Current version: {current}")
    print(f"Previous version: {previous or '[none]'}")
    print(f"Release needed: {'yes' if release_needed else 'no'}")

    _write_outputs(
        {
            "version": current,
            "previous_version": previous or "",
            "release_needed": str(release_needed).lower(),
        }
    )


def _run(command: list[str], *, capture_output: bool = False) -> subprocess.CompletedProcess[str]:
    print(f"Running: {' '.join(command)}")
    return subprocess.run(
        command,
        cwd=ROOT,
        check=True,
        text=True,
        capture_output=capture_output,
    )


def cmd_build() -> None:
    if DIST_DIR.exists():
        shutil.rmtree(DIST_DIR)
    _run(["uv", "build"])


def cmd_publish() -> None:
    env = os.environ.copy()
    token = env.get("UV_PUBLISH_TOKEN") or env.get("PYPI_TOKEN")
    if not token:
        raise ReleaseError("Publishing requires UV_PUBLISH_TOKEN or PYPI_TOKEN to be set")

    env["UV_PUBLISH_TOKEN"] = token
    _run(["uv", "publish"], capture_output=False)


COMMANDS = {
    "detect": cmd_detect,
    "build": cmd_build,
    "publish": cmd_publish,
}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Release utility helpers")
    parser.add_argument("command", choices=COMMANDS.keys(), help="Command to run")
    args = parser.parse_args(argv)

    try:
        COMMANDS[args.command]()
    except ReleaseError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as exc:
        print(exc.stdout)
        print(exc.stderr, file=sys.stderr)
        return exc.returncode

    return 0


if __name__ == "__main__":
    sys.exit(main())
