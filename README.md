# MCP macOS Control Server

This repository hosts an experimental Model Context Protocol (MCP) server that exposes macOS automation features to large language models. The implementation is written in Python using [FastMCP](https://github.com/pingdotgg/fastmcp) and wraps AppleScript automation scripts so MCP clients can invoke common Apple application actions.

## Status

- ✅ **Mail**: listing accounts and mailboxes, fetching latest/unread/search results, and sending email through Apple Mail are available via dedicated MCP tools.
- ⏳ **Planned**: Notes, Messages, Reminders, Contacts, Calendar and other macOS apps will follow the same structure—each with its own tool module and AppleScript scripts.

## Project layout

```
src/mcp_macos/
├── __init__.py          # FastMCP hub registering application sub-servers
├── scripts/             # AppleScript sources (grouped by application)
├── tools/               # FastMCP sub-servers (one per application)
└── utils/applescript.py # Helpers to load and execute AppleScript files
```

Each tool module calls into the corresponding scripts to keep AppleScript logic separate from Python orchestration. The hub imports each app-specific `FastMCP` server using `import_server`, so clients see a single manifest with prefixed tool names.

## Getting started

1. Install dependencies (requires Python 3.12):
   ```bash
   uv sync
   ```
2. Run the MCP hub:
   ```bash
   uv run fastmcp dev src/mcp_macos/__init__.py
   ```
   or execute the packaged entry point:
   ```bash
   uv run mcp-macos
   ```

When connecting through an MCP client (e.g., Claude Desktop), ensure the Apple applications you control have granted automation permissions to your terminal or host app.

## Adding new applications

1. Create `src/mcp_macos/scripts/<app>/` with AppleScript files for each action.
2. Implement `src/mcp_macos/tools/<app>.py` with FastMCP tools that call those scripts.
3. Import the new sub-server in `src/mcp_macos/__init__.py`.

Follow the Mail module as a reference; it demonstrates parsing AppleScript output into JSON-friendly data structures that MCP clients can consume reliably.
