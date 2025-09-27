from __future__ import annotations
from fastmcp import FastMCP
from ..utils import run_applescript, tsv_to_dicts, iso_to_local_components

mcp = FastMCP("macos-calendar")


@mcp.tool
def list_next_events(days_ahead: int = 7, limit: int = 20) -> list[dict]:
    """Upcoming events across all calendars. Keys: start, end, title, calendar."""
    out = run_applescript("cal_list_next_events.applescript", str(days_ahead), str(limit))
    return tsv_to_dicts(out, ["start", "end", "title", "calendar"])


@mcp.tool
def create_event_at(
    title: str,
    start_iso: str,
    duration_minutes: int = 30,
    calendar_name: str | None = None,
) -> str:
    """
    Create an event starting at ISO formatted `start_iso` for `duration_minutes`.
    `calendar_name` optional (defaults to first calendar).
    """
    y, mo, d, h, mi, s = iso_to_local_components(start_iso)
    cal = calendar_name or ""
    # argv: title, year, month, day, hour, minute, second, duration_minutes, [calendar_name]
    args = [title, y, mo, d, h, mi, s, str(duration_minutes)]
    if cal:
        args.append(cal)
    run_applescript("cal_create_event_at.applescript", *args)
    return "OK"
