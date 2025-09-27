from __future__ import annotations
from typing import Literal

from fastmcp import FastMCP
from ..utils import run_applescript, tsv_to_dicts, split_recipients

mcp = FastMCP("macos-mail")


@mcp.tool
def list_emails(
    status: Literal["any", "unread", "read"] = "any",
    query: str | None = None,
    mailbox: str | None = None,
    limit: int = 10,
) -> list[dict]:
    """
    List recent emails, optionally filtering by status (any/unread/read), mailbox, or search query.
    Always includes a body preview (first 500 characters).
    """
    limit_value = max(1, min(limit, 30))

    mailbox_arg = mailbox.strip() if mailbox else ""
    query_arg = query.strip() if query else ""

    out = run_applescript(
        "mail_list_emails.applescript",
        str(limit_value),
        status.lower(),
        mailbox_arg,
        query_arg,
        "500",
    )
    rows = tsv_to_dicts(
        out,
        ["id", "received", "from", "account", "status", "subject", "body"],
    )
    # status already a nice string (Read/Unread)
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


@mcp.tool
def list_accounts() -> list[dict]:
    """List Mail accounts. Keys: name."""
    out = run_applescript("mail_list_accounts.applescript")
    return tsv_to_dicts(out, ["name"]) if out else []


@mcp.tool
def list_mailboxes(account: str | None = None) -> list[dict]:
    """
    List mailboxes. Keys: mailbox, account, unread.
    If `account` is provided, only mailboxes of that account are returned.
    """
    acc = account.strip() if account else ""
    out = run_applescript("mail_list_mailboxes.applescript", acc)
    rows = tsv_to_dicts(out, ["mailbox", "account", "unread"]) if out else []
    for row in rows:
        try:
            row["unread"] = int(row.get("unread", "0") or 0)
        except Exception:
            row["unread"] = 0
    return rows


@mcp.tool
def overview(limit_recent: int = 5) -> dict:
    """
    High-level Mail overview with accounts, per-account inbox unread, and recent emails
    from the primary Inbox.
    """
    accounts = [a.get("name", "") for a in list_accounts.fn()]  # type: ignore[attr-defined]
    try:
        unread_str = run_applescript("mail_unread_inbox_count.applescript")
        inbox_unread = int(unread_str or 0)
    except Exception:
        inbox_unread = 0
    # Per-account Inbox unread counts
    accounts_info: list[dict] = []
    for acc in accounts:
        inbox_unread_acc = 0
        try:
            mboxes = list_mailboxes.fn(acc)  # type: ignore[attr-defined]
            for mb in mboxes:
                if (mb.get("mailbox", "").lower() == "inbox"):
                    inbox_unread_acc = int(mb.get("unread", 0) or 0)
                    break
        except Exception:
            pass
        accounts_info.append({"name": acc, "inbox_unread": inbox_unread_acc})

    recent = list_emails.fn(limit=max(1, min(limit_recent, 10)), mailbox="Inbox")  # type: ignore[attr-defined]
    return {
        "accounts": accounts_info,
        "inbox_unread_total": inbox_unread,
        "primary_inbox_recent": recent,
    }


@mcp.tool
def get_email(id: str) -> dict:
    """Fetch a single email by its Apple Mail `id` with full body content."""
    out = run_applescript("mail_get_email_by_id.applescript", id)
    rows = tsv_to_dicts(
        out,
        [
            "subject",
            "from",
            "to",
            "cc",
            "id",
            "received",
            "mailbox",
            "read",
            "message_id",
            "preview",
            "body",
        ],
    )
    if not rows:
        raise ValueError("Email not found")
    row = rows[0]
    row["read"] = row.get("read", "").lower() == "true"
    return row
