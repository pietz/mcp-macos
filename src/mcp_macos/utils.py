from __future__ import annotations
from pathlib import Path
import subprocess
from datetime import datetime

BASE = Path(__file__).resolve().parent
SCRIPTS = BASE / "scripts"


def run_applescript(filename: str, *args: str) -> str:
    """Run an AppleScript file with argv; return stdout (stripped) or raise."""
    path = str((SCRIPTS / filename).resolve())
    proc = subprocess.run(["osascript", path, *args], capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "AppleScript error")
    return proc.stdout.strip()


def tsv_to_dicts(s: str, keys: list[str]) -> list[dict]:
    rows: list[dict] = []
    if not s:
        return rows
    for line in s.splitlines():
        parts = line.split("\t")
        rows.append({k: (parts[i] if i < len(parts) else "") for i, k in enumerate(keys)})
    return rows


def split_recipients(to: str) -> list[str]:
    """Accept comma, semicolon, or newline-separated recipients."""
    raw = to.replace(";", ",").replace("\r", "\n").replace(",", "\n")
    return [x.strip() for x in raw.split("\n") if x.strip()]


def iso_to_local_components(iso_datetime: str) -> list[str]:
    """Convert ISO datetime string to local Y, M, D, h, m, s strings."""
    raw = iso_datetime.strip()
    if raw.endswith("Z"):
        raw = f"{raw[:-1]}+00:00"
    dt = datetime.fromisoformat(raw)
    if dt.tzinfo is not None:
        dt = dt.astimezone()
    return [
        str(dt.year),
        str(dt.month),
        str(dt.day),
        str(dt.hour),
        str(dt.minute),
        str(dt.second),
    ]
