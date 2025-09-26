from __future__ import annotations

import json
import logging
import subprocess
from importlib import resources
from typing import Any

logger = logging.getLogger(__name__)


class AppleScriptError(RuntimeError):
    """Raised when an AppleScript execution fails."""

    def __init__(self, message: str, *, stdout: str, stderr: str, returncode: int) -> None:
        super().__init__(message)
        self.stdout = stdout
        self.stderr = stderr
        self.returncode = returncode


def _load_script(app: str, script_name: str) -> str:
    try:
        script_resource = resources.files(f"mcp_macos.scripts.{app}") / script_name
    except ModuleNotFoundError as exc:  # pragma: no cover - defensive
        raise FileNotFoundError(f"Unknown script package for app '{app}'") from exc

    try:
        return script_resource.read_text(encoding="utf-8")
    except FileNotFoundError as exc:  # pragma: no cover - defensive
        raise FileNotFoundError(f"AppleScript '{script_name}' for app '{app}' not found") from exc


def run_script(app: str, script_name: str, *args: Any, timeout: float | None = 15.0) -> str:
    """Run an AppleScript from our packaged scripts and return its stdout."""

    script_source = _load_script(app, script_name)
    command: list[str] = ["osascript", "-s", "s", "-"]
    command.extend(str(arg) for arg in args if arg is not None)

    process = subprocess.run(
        command,
        input=script_source,
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
    )

    stdout = process.stdout.strip()
    stderr = process.stderr.strip()

    if process.returncode != 0:
        message = f"AppleScript '{script_name}' for {app} failed with exit code {process.returncode}"
        raise AppleScriptError(message, stdout=stdout, stderr=stderr, returncode=process.returncode)

    if stderr:
        logger.warning("AppleScript '%s' for %s reported: %s", script_name, app, stderr)

    return stdout


def run_json_script(app: str, script_name: str, *args: Any, timeout: float | None = 15.0) -> Any:
    """Run a script and parse the JSON response."""

    raw_output = run_script(app, script_name, *args, timeout=timeout)
    if not raw_output:
        return None

    try:
        return json.loads(raw_output)
    except json.JSONDecodeError as exc:
        raise AppleScriptError(
            f"Failed to decode JSON output from '{script_name}'",
            stdout=raw_output,
            stderr="",
            returncode=0,
        ) from exc


def parse_line_output(raw_output: str) -> list[str]:
    """Split a newline-separated AppleScript response into a list."""

    if not raw_output:
        return []
    return [line for line in raw_output.splitlines() if line]


def parse_tabular_output(raw_output: str) -> list[tuple[str, str]]:
    """Parse rows separated by newlines with tab-delimited columns."""

    if not raw_output:
        return []

    rows: list[tuple[str, str]] = []
    for line in raw_output.splitlines():
        if "\t" not in line:
            continue
        account, mailbox = line.split("\t", 1)
        rows.append((account, mailbox))
    return rows
