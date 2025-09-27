from __future__ import annotations
from typing import Literal

from fastmcp import FastMCP
from ..utils import run_applescript, tsv_to_dicts, split_recipients

mcp = FastMCP("macos-mail")


@mcp.tool
def list_emails(
    status: Literal["all", "unread", "read"] = "all",
    mailbox: str | None = None,
    limit: int = 10,
    query: str | None = None,
) -> list[dict]:
    """
    List recent emails, optionally filtering by status (all/unread/read), mailbox, or search query.
    Always includes a body preview (first 500 characters).
    """
    limit_value = max(1, min(limit, 30))
    status_lower = status.lower()
    status_map = {"all": "any", "unread": "unread", "read": "read"}
    if status_lower not in status_map:
        raise ValueError("status must be 'all', 'unread', or 'read'")
    status_arg = status_map[status_lower]

    mailbox_arg = mailbox.strip() if mailbox else ""
    query_arg = query.strip() if query else ""

    out = run_applescript(
        "mail_list_emails.applescript",
        str(limit_value),
        status_arg,
        mailbox_arg,
        query_arg,
        "500",
    )
    rows = tsv_to_dicts(
        out,
        ["subject", "from", "id", "received", "mailbox", "read", "preview"],
    )
    for row in rows:
        row["read"] = row.get("read", "").lower() == "true"
    return rows


@mcp.tool
def send(to: str, subject: str, body: str, visible: bool = False) -> str:
    """
    Send an email via Apple Mail. `to` may be comma/semicolon/newline separated.
    """
    recips = split_recipients(to)
    vis = "true" if visible else "false"
    # argv: subject, body, visible, recipients...
    run_applescript("mail_send.applescript", subject, body, vis, *recips)
    return "OK"
