from __future__ import annotations
from typing import Literal

from fastmcp import FastMCP
from ..utils import run_applescript, tsv_to_dicts

mcp = FastMCP("macos-mail")


@mcp.tool
def list_emails(
    status: Literal["any", "unread", "read"] = "any",
    query: str | None = None,
    account: str | None = None,
    mailbox: str | None = None,
    limit: int = 10,
) -> list[dict]:
    """
    List recent emails. Optionally filter by status, account, mailbox, or search query.
    """
    limit_value = max(1, min(limit, 30))

    mailbox_arg = mailbox.strip() if mailbox else ""
    query_arg = query.strip() if query else ""
    account_arg = account.strip() if account else ""

    out = run_applescript(
        "mail_list_emails.applescript",
        str(limit_value),
        status.lower(),
        account_arg,
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
def send_email(
    to: list[str],
    subject: str,
    body: str,
    cc: list[str] | None = None,
    message_id: str | None = None,
) -> str:
    """
    Send an email. If `message_id` is provided, it's a reply or forward.
    `to` must contain at least one recipient email; `cc` optional.
    """
    to_recipients = [r.strip() for r in to if r.strip()]
    if not to_recipients:
        raise ValueError("At least one 'to' recipient is required")

    cc_list = cc or []
    cc_recipients = [r.strip() for r in cc_list if r.strip()]
    message_arg = message_id.strip() if message_id else ""
    # argv: subject, body, message_id, to_count, cc_count, to..., cc...
    run_applescript(
        "mail_send.applescript",
        subject,
        body,
        message_arg,
        str(len(to_recipients)),
        str(len(cc_recipients)),
        *to_recipients,
        *cc_recipients,
    )
    return "OK"


def _list_accounts() -> list[str]:
    out = run_applescript("mail_list_accounts.applescript")
    rows = tsv_to_dicts(out, ["name"]) if out else []
    return [row.get("name", "") for row in rows if row.get("name")]


def _list_mailboxes(account: str) -> list[dict]:
    out = run_applescript("mail_list_mailboxes.applescript", account)
    rows = tsv_to_dicts(out, ["mailbox", "account", "unread"]) if out else []
    for row in rows:
        try:
            row["unread"] = int(row.get("unread", "0") or 0)
        except Exception:
            row["unread"] = 0
        row["mailbox"] = row.get("mailbox", "")
        row["account"] = row.get("account", "")
    return rows


@mcp.tool
def overview() -> dict:
    """
    High-level snapshot of Mail accounts, their mailboxes, and the three most recent
    emails per account.
    """
    accounts = _list_accounts()
    accounts_info: list[dict] = []

    try:
        unread_str = run_applescript("mail_unread_inbox_count.applescript")
        inbox_unread = int(unread_str or 0)
    except Exception:
        inbox_unread = 0

    for account in accounts:
        mailboxes = _list_mailboxes(account)
        recent_emails = list_emails.fn(account=account, limit=3)  # type: ignore[attr-defined]
        accounts_info.append(
            {
                "name": account,
                "mailboxes": mailboxes,
                "recent_emails": recent_emails,
            }
        )

    return {
        "accounts": accounts_info,
        "inbox_unread_total": inbox_unread,
    }


@mcp.tool
def read_email(id: str) -> dict:
    """Fetch a single email by its Apple Mail `id` with full body content.

    Returns keys: id, received, from, account, status, subject, body
    """
    out = run_applescript("mail_get_email_by_id.applescript", id)
    rows = tsv_to_dicts(
        out,
        [
            "id",
            "received",
            "from",
            "account",
            "status",
            "subject",
            "body",
        ],
    )
    if not rows:
        raise ValueError("Email not found")
    row = rows[0]
    return row


@mcp.tool
def update_email_status(
    id: str,
    action: Literal["mark_read", "mark_unread", "archive"],
) -> str:
    """Update an email's state by Apple Mail `id`. Actions: mark_read, mark_unread, archive."""

    result = run_applescript("mail_update_email_status.applescript", id, action)
    if result and result != "OK":
        raise RuntimeError(result)
    return "OK"
