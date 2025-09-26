from __future__ import annotations

from typing import Any, TypedDict

from fastmcp import FastMCP

from ..utils.applescript import (
    AppleScriptError,
    parse_line_output,
    parse_tabular_output,
    run_json_script,
    run_script,
)


class MailMessage(TypedDict, total=False):
    subject: str
    sender: str
    date: str
    account: str
    mailbox: str
    is_read: bool
    id: str
    preview: str


class MailboxEntry(TypedDict):
    account: str
    mailbox: str


mail_server = FastMCP("Mail")


def _clamp_limit(limit: int | None) -> int:
    if limit is None:
        return 10
    if limit < 1:
        return 1
    if limit > 50:
        return 50
    return limit


def _fetch_messages(script: str, *args: Any) -> list[MailMessage]:
    try:
        payload = run_json_script("mail", script, *args)
    except AppleScriptError as exc:
        raise RuntimeError(str(exc)) from exc

    if payload in (None, ""):
        return []

    if not isinstance(payload, list):
        raise RuntimeError(f"Unexpected payload from {script}: {payload!r}")

    results: list[MailMessage] = []
    for item in payload:
        if not isinstance(item, dict):
            continue
        message: MailMessage = {
            "subject": str(item.get("subject", "")),
            "sender": str(item.get("sender", "")),
            "date": str(item.get("date", "")),
            "account": str(item.get("account", "")),
            "mailbox": str(item.get("mailbox", "")),
            "is_read": bool(item.get("is_read", False)),
            "id": str(item.get("id", "")),
            "preview": str(item.get("preview", "")),
        }
        results.append(message)
    return results


@mail_server.tool
def list_accounts() -> dict[str, list[str]]:
    """List available Apple Mail accounts."""
    try:
        raw_output = run_script("mail", "list_accounts.applescript")
    except AppleScriptError as exc:
        raise RuntimeError(str(exc)) from exc
    return {"accounts": parse_line_output(raw_output)}


@mail_server.tool
def list_mailboxes(account: str | None = None) -> dict[str, list[MailboxEntry]]:
    """List mailboxes for all accounts or a specific account."""
    try:
        raw_output = run_script("mail", "list_mailboxes.applescript", account or "")
    except AppleScriptError as exc:
        raise RuntimeError(str(exc)) from exc
    mailboxes: list[MailboxEntry] = [
        {"account": acc, "mailbox": box} for acc, box in parse_tabular_output(raw_output)
    ]
    return {"mailboxes": mailboxes}


@mail_server.tool
def get_unread(
    account: str | None = None,
    mailbox: str | None = None,
    limit: int | None = 10,
) -> dict[str, Any]:
    """Retrieve unread messages from Apple Mail."""
    limited = _clamp_limit(limit)
    messages = _fetch_messages(
        "get_unread.applescript",
        limited,
        account or "",
        mailbox or "",
    )
    return {"messages": messages, "limit": limited}


@mail_server.tool
def get_latest(
    account: str | None = None,
    mailbox: str | None = None,
    limit: int | None = 10,
) -> dict[str, Any]:
    """Retrieve the latest messages from Apple Mail."""
    limited = _clamp_limit(limit)
    messages = _fetch_messages(
        "get_latest.applescript",
        limited,
        account or "",
        mailbox or "",
    )
    return {"messages": messages, "limit": limited}


@mail_server.tool
def search_messages(
    search_term: str,
    account: str | None = None,
    mailbox: str | None = None,
    limit: int | None = 10,
) -> dict[str, Any]:
    """Search messages in Apple Mail."""
    if not search_term:
        raise ValueError("search_term cannot be empty")

    limited = _clamp_limit(limit)
    messages = _fetch_messages(
        "search_messages.applescript",
        search_term,
        limited,
        account or "",
        mailbox or "",
    )
    return {"messages": messages, "limit": limited, "search_term": search_term}


@mail_server.tool
def send_message(
    to: str,
    subject: str,
    body: str,
    cc: str | None = None,
    bcc: str | None = None,
    sender: str | None = None,
) -> dict[str, Any]:
    """Send a message via Apple Mail."""
    if not to:
        raise ValueError("Recipient email (to) is required")
    if not subject:
        raise ValueError("Subject is required")

    try:
        result = run_script(
            "mail",
            "send_message.applescript",
            to,
            subject,
            body,
            cc or "",
            bcc or "",
            sender or "",
        )
    except AppleScriptError as exc:
        raise RuntimeError(str(exc)) from exc

    if not result or result.upper() != "OK":
        raise RuntimeError(f"Mail send returned unexpected response: {result!r}")

    return {
        "status": "sent",
        "to": to,
        "subject": subject,
        "used_sender": sender,
    }
