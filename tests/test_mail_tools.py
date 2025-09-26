from __future__ import annotations

import pytest

from mcp_macos.tools import mail as mail_module
from mcp_macos.utils.applescript import AppleScriptError


def test_list_accounts(monkeypatch):
    called = {}

    def fake_run_script(app: str, script: str, *args: str) -> str:
        called["app"] = app
        called["script"] = script
        called["args"] = args
        return "Account A\nAccount B\n"

    monkeypatch.setattr(mail_module, "run_script", fake_run_script)

    result = mail_module._list_accounts()

    assert called == {"app": "mail", "script": "list_accounts.applescript", "args": ()}
    assert result == {"accounts": ["Account A", "Account B"]}


def test_list_mailboxes(monkeypatch):
    def fake_run_script(app: str, script: str, *args: str) -> str:
        assert app == "mail"
        assert script == "list_mailboxes.applescript"
        assert args == ("",)
        return "Account A\tInbox\nAccount B\tArchive\n"

    monkeypatch.setattr(mail_module, "run_script", fake_run_script)

    result = mail_module._list_mailboxes()

    assert result == {
        "mailboxes": [
            {"account": "Account A", "mailbox": "Inbox"},
            {"account": "Account B", "mailbox": "Archive"},
        ]
    }


def test_get_unread(monkeypatch):
    expected_args = {}

    def fake_run_json_script(app: str, script: str, *args: str):
        expected_args["app"] = app
        expected_args["script"] = script
        expected_args["args"] = args
        return [
            {
                "subject": "Subject",
                "sender": "sender@example.com",
                "date": "today",
                "account": "Account A",
                "mailbox": "Inbox",
                "is_read": False,
                "id": "123",
                "preview": "preview",
            }
        ]

    monkeypatch.setattr(mail_module, "run_json_script", fake_run_json_script)

    result = mail_module._get_unread(limit=5, account="Account A", mailbox="Inbox")

    assert expected_args == {
        "app": "mail",
        "script": "get_unread.applescript",
        "args": (5, "Account A", "Inbox"),
    }
    assert result["limit"] == 5
    assert result["messages"][0]["subject"] == "Subject"


def test_get_unread_applescript_error(monkeypatch):
    def fake_run_json_script(*args, **kwargs):
        raise AppleScriptError("boom", stdout="", stderr="", returncode=1)

    monkeypatch.setattr(mail_module, "run_json_script", fake_run_json_script)

    with pytest.raises(RuntimeError):
        mail_module._get_unread()


def test_get_latest_clamps_limit(monkeypatch):
    def fake_run_json_script(app: str, script: str, *args: str):
        assert args[0] == 50  # limit should be clamped to 50
        return []

    monkeypatch.setattr(mail_module, "run_json_script", fake_run_json_script)

    result = mail_module._get_latest(limit=200)

    assert result == {"messages": [], "limit": 50}


def test_search_messages_requires_query():
    with pytest.raises(ValueError):
        mail_module._search_messages(search_term="")


def test_search_messages(monkeypatch):
    def fake_run_json_script(app: str, script: str, *args: str):
        assert script == "search_messages.applescript"
        assert args[0] == "Invoice"
        return []

    monkeypatch.setattr(mail_module, "run_json_script", fake_run_json_script)

    result = mail_module._search_messages(search_term="Invoice", limit=2)

    assert result == {"messages": [], "limit": 2, "search_term": "Invoice"}


def test_send_message_success(monkeypatch):
    captured = {}

    def fake_run_script(app: str, script: str, *args: str) -> str:
        captured["app"] = app
        captured["script"] = script
        captured["args"] = args
        return "OK"

    monkeypatch.setattr(mail_module, "run_script", fake_run_script)

    result = mail_module._send_message(
        to="user@example.com",
        subject="Hello",
        body="Hi there",
        cc="cc@example.com",
        bcc="bcc@example.com",
        sender="sender@example.com",
    )

    assert captured == {
        "app": "mail",
        "script": "send_message.applescript",
        "args": (
            "user@example.com",
            "Hello",
            "Hi there",
            "cc@example.com",
            "bcc@example.com",
            "sender@example.com",
        ),
    }
    assert result == {
        "status": "sent",
        "to": "user@example.com",
        "subject": "Hello",
        "used_sender": "sender@example.com",
    }


@pytest.mark.parametrize(
    "kwargs, error_message",
    [
        ({"subject": "Hello", "body": "Body"}, "Recipient email (to) is required"),
        ({"to": "user@example.com", "body": "Body"}, "Subject is required"),
    ],
)
def test_send_message_validation_errors(kwargs, error_message):
    with pytest.raises(ValueError, match=error_message):
        call_kwargs = {"to": "", "subject": "", "body": ""}
        call_kwargs.update(kwargs)

        with pytest.raises(ValueError, match=error_message):
            mail_module._send_message(**call_kwargs)


def test_send_message_non_ok(monkeypatch):
    def fake_run_script(app: str, script: str, *args: str) -> str:
        return "NOT_OK"

    monkeypatch.setattr(mail_module, "run_script", fake_run_script)

    with pytest.raises(RuntimeError):
        mail_module._send_message(to="user@example.com", subject="Hi", body="Body")
