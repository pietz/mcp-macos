from __future__ import annotations

import pytest

from mcp_macos.servers import mail
from mcp_macos.utils import split_recipients


def test_list_emails_parses_results(monkeypatch: pytest.MonkeyPatch) -> None:
    captured_args: tuple[str, tuple[str, ...]] | None = None

    def fake_run(script_name: str, *args: str) -> str:
        nonlocal captured_args
        captured_args = (script_name, args)
        return (
            "Subject\tSender\t123\t2024-01-01\tInbox\tfalse\tPreview text\n"
            "Other\tAnother\t456\t2024-01-02\tWork\ttrue\tMore preview"
        )

    monkeypatch.setattr(mail, "run_applescript", fake_run)
    rows = mail.list_emails.fn(limit=5)
    assert rows == [
        {
            "subject": "Subject",
            "from": "Sender",
            "id": "123",
            "received": "2024-01-01",
            "mailbox": "Inbox",
            "read": False,
            "preview": "Preview text",
        },
        {
            "subject": "Other",
            "from": "Another",
            "id": "456",
            "received": "2024-01-02",
            "mailbox": "Work",
            "read": True,
            "preview": "More preview",
        },
    ]
    assert captured_args == (
        "mail_list_emails.applescript",
        ("5", "any", "", "", "500"),
    )


def test_list_emails_converts_arguments(monkeypatch: pytest.MonkeyPatch) -> None:
    captured_args: tuple[str, tuple[str, ...]] | None = None

    def fake_run(script_name: str, *args: str) -> str:
        nonlocal captured_args
        captured_args = (script_name, args)
        return ""

    monkeypatch.setattr(mail, "run_applescript", fake_run)
    mail.list_emails.fn(status="unread", mailbox="Inbox", limit=50, query="invoice")
    assert captured_args == (
        "mail_list_emails.applescript",
        ("30", "unread", "Inbox", "invoice", "500"),
    )


def test_list_emails_handles_read_filter(monkeypatch: pytest.MonkeyPatch) -> None:
    captured_args: tuple[str, tuple[str, ...]] | None = None

    def fake_run(script_name: str, *args: str) -> str:
        nonlocal captured_args
        captured_args = (script_name, args)
        return "Subject\tSender\t123\t2024-01-01\tInbox\ttrue\tPreview"

    monkeypatch.setattr(mail, "run_applescript", fake_run)
    rows = mail.list_emails.fn(status="read")
    assert rows[0]["read"] is True
    assert captured_args == (
        "mail_list_emails.applescript",
        ("10", "read", "", "", "500"),
    )


def test_send_handles_multiple_recipients(monkeypatch: pytest.MonkeyPatch) -> None:
    captured_args: tuple[str, tuple[str, ...]] | None = None

    def fake_run(script_name: str, *args: str) -> str:
        nonlocal captured_args
        captured_args = (script_name, args)
        return "OK"

    monkeypatch.setattr(mail, "run_applescript", fake_run)
    result = mail.send.fn(
        to="a@example.com, b@example.com; c@example.com\n",
        subject="Subject",
        body="Body",
        visible=True,
    )
    assert result == "OK"
    assert captured_args == (
        "mail_send.applescript",
        ("Subject", "Body", "true", "a@example.com", "b@example.com", "c@example.com"),
    )


def test_split_recipients_parses_common_separators() -> None:
    recipients = split_recipients("one@example.com;two@example.com,three@example.com\n four@example.com")
    assert recipients == [
        "one@example.com",
        "two@example.com",
        "three@example.com",
        "four@example.com",
    ]
