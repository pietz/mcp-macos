# Model Context Protocol (MCP)

The Model Context Protocol (MCP) is an open standard to extend LLMs with external functionalities like tools, resources and prompts. In a regular application we would use a REST API to communicate with external entities. With LLMs we use MCP.

MCP works on client-server relationship based on a chosen transport protocol.

- Clients are the LLM host applications - The core wrapper around the LLM
- Servers are the external capability providers run either locally or remotely
- Transport protocol is either STDIO, HTTP or SSE - with STDIO being the default

A client like Claude Desktop can connect to multiple servers, each providing multiple tools.


## Python & FastMCP
Building MCP servers in Python can be done with the official `mcp` package. However, a community project called `fastmcp` acts as a superset of MCP functionalities making the implementation both easier and more flexible. It has become so popular that `mcp`has integrated version 1.0 of `fastmcp` in the official package. We stick to using `fastmcp` directly due to many new features in the 2.X release.

## Quickstart

Install the package
```bash
uv add fastmcp
```

Create a server
```python
# main.py
from datetime import datetime
from zoneinfo import ZoneInfo

from fastmcp import FastMCP

mcp = FastMCP("Timestamp")

@mcp.tool
def current_timestamp(tz: str | None = None) -> str:
    """Return the current timestamp in ISO 8601 format."""
    zone = ZoneInfo(tz) if tz else ZoneInfo("UTC")
    return datetime.now(zone).isoformat()

if __name__ == "__main__":
    mcp.run()
```

Run the server
```bash
uv run main.py
```

Run in dev mode for manual testing
```bash
uv run fastmcp dev main.py
```

FastMCP infers tool schemas from type hints and docstrings. The `@mcp.tool`
decorator works on sync or async callables. Return values can be strings,
JSON-serialisable objects, or media helpers (`Image`, `Audio`, etc.).

## Core Entities
FastMCP exposes three capability types. Reach for tools first; switch to
resources when you only need to surface read-only data, and prompts when you
want reusable instruction text.

- **Tools** (`@mcp.tool`): imperative callables that can read state, call other
  services, and perform side effects. Make new features available through tools
  unless you have a reason not to.
- **Resources** (`@mcp.resource("uri")`): structured, read-only views reached
  via URIs (static or templated).
- **Prompts** (`@mcp.prompt`): templates that clients can inject into LLM
  conversations.

### Tools
```python
@mcp.tool
def create_reminder(title: str, due: str | None = None) -> dict[str, str | None]:
    return {"title": title, "due": due}
```
Add context parameters later if you need logging, progress reporting, or other
advanced behaviours (see “Context & Advanced Interactions”).

### Resources
```python
@mcp.resource("calendar://upcoming")
def next_events() -> list[dict[str, str]]:
    return load_events()

@mcp.resource("mail://{mailbox}/messages")
def mailbox(mailbox: str) -> list[dict[str, str]]:
    return fetch_messages(mailbox)
```
FastMCP prefixes resource URIs automatically when importing sub-servers (see
Composition below).

### Prompts
```python
@mcp.prompt
def compose_email(recipient: str, subject: str) -> str:
    return f"Draft a polite email to {recipient} with subject '{subject}'."
```
Prompt outputs can be plain strings or richer message blocks.

## Context & Advanced Interactions
When a tool, resource, or prompt accepts a `Context` parameter, FastMCP injects
runtime helpers so you can:
- `await ctx.info("...")`, `await ctx.warning("...")`, `await ctx.log(...)` for
  structured logging
- `await ctx.report_progress(0.5, message="halfway")` to surface progress
- `await ctx.read_resource(uri)` or `await ctx.sample(prompt)` to call back into
  MCP capabilities
- `await ctx.elicit("Continue?", choices=[...])` to confirm sensitive actions

Example combining logging, resource access, and sampling:
```python
from fastmcp import Context

@mcp.tool
async def summarize_calendar(ctx: Context) -> str:
    await ctx.info("Fetching upcoming events")
    events = await ctx.read_resource("calendar://upcoming")
    prompt = "Summarise these events: " + events.content[0].text
    summary = await ctx.sample(prompt)
    return summary.text
```

Add the `Context` argument only when you need these advanced behaviours—keep
entry-level examples simple so newcomers can focus on decorators and typing.

## Composition with `import_server`
Keep each macOS domain in its own FastMCP server and copy the capabilities into
a central hub at startup. `import_server` performs a one-time copy, so the hub
has no runtime dependency on the sub-server once the import completes.

```python
# main.py
import asyncio
from fastmcp import FastMCP
from calendar_server import calendar  # FastMCP("Calendar") defined elsewhere
from mail_server import mail          # FastMCP("Mail") defined elsewhere

hub = FastMCP("macOS Hub")


async def register_modules() -> None:
    await hub.import_server(calendar, prefix="calendar")
    await hub.import_server(mail, prefix="mail")


if __name__ == "__main__":
    asyncio.run(register_modules())
    hub.run()
```

Imported tools are prefixed (for example `calendar_next_event`) so each domain
stays organised inside the hub’s manifest.

## Proxying & Integrations
FastMCP can front remote MCP servers or auto-generate capabilities from
existing HTTP services.

### Proxy a remote MCP server
```python
from fastmcp import Client, FastMCP

weather_proxy = FastMCP.as_proxy(
    name="Weather Proxy",
    client_factory=lambda: Client("https://weather.example.com/mcp"),
)

hub = FastMCP("macOS Hub")


async def attach_proxy() -> None:
    await hub.import_server(weather_proxy, prefix="weather")


if __name__ == "__main__":
    import asyncio

    asyncio.run(attach_proxy())
    hub.run()
```

## Middleware & Tool Transformations
FastMCP ships with a middleware system and tool transformations:
- Middleware can inspect/modify MCP requests, enforce policies, or inject
  tracing. Middleware functions receive a `MiddlewareContext` from which you can
  access the FastMCP context, request metadata, and call `next`.
- Tool transformations rewrite inputs/outputs (e.g., constrain arguments,
  redact sensitive fields) without touching the original tool implementation.

## Authentication
FastMCP provides ready-made auth providers:
```python
from fastmcp import FastMCP
from fastmcp.server.auth import GoogleProvider

auth = GoogleProvider(client_id="...", client_secret="...", base_url="...")
mcp = FastMCP("Secured Server", auth=auth)
```
Clients can connect with `Client(..., auth="oauth")` for browser-based flows.
Other providers include GitHub, Azure AD, Auth0, WorkOS, Descope, JWT, and API
keys.

## Clients & Testing
The FastMCP client library hits any MCP server over STDIO, HTTP, SSE, or
in-memory transports. Example in-memory test:
```python
from fastmcp import Client, FastMCP

async def test_add():
    server = FastMCP("Test")

    @server.tool
    def add(a: int, b: int) -> int:
        return a + b

    async with Client(server) as client:
        result = await client.call_tool("add", {"a": 2, "b": 3})
        assert result.content[0].text == "5"
```
Using the in-memory transport avoids subprocesses in unit tests.

## Transports & Deployment
`FastMCP.run()` defaults to STDIO. Other options:
```python
mcp.run(transport="http", host="0.0.0.0", port=8000, path="/mcp")
mcp.run(transport="sse", host="0.0.0.0", port=8000)
```

For ASGI integration:
```python
from fastmcp.server.transport.http import create_streamable_http_app

app = create_streamable_http_app(mcp)
```
Deploy behind Uvicorn/Hypercorn or use FastMCP Cloud (managed hosting) when you
need HTTPS and built-in auth quickly.

## Resources & Subscriptions
- `@mcp.resource_subscription("uri")` streams changes to clients
- `@mcp.streaming_resource("uri")` returns chunked/binary data
- `@mcp.resource_completion` and `@mcp.prompt_completion` provide completion
  hints for arguments.

## Development Workflow
1. Design the domain module (Calendar, Mail, etc.) as its own FastMCP server.
2. Write tests using the in-memory client.
3. Import sub-servers (and attach proxies if needed) into the main `main.py` hub.
4. Run `uv run fastmcp dev main.py` to inspect the combined manifest.
5. Package and publish with `uv build` / `uv publish` when ready.

Handy CLI commands:
```bash
uv run fastmcp run main.py       # launch via STDIO
uv run fastmcp dev main.py       # interactive inspector
uv run fastmcp ls                # list installed servers
uv run fastmcp install main.py   # install via manifest
```

## Usability & Tool Design
### Embed Flexibility Without Overload
Each tool becomes part of the LLM's working context, so keep the surface area compact. Prefer a single tool with well-chosen parameters over several near-identical endpoints when they return the same shape of data. Follow the `list_emails` pattern: defaults cover the common case, optional flags (for unread, query strings, etc.) unlock variations without multiplying manifest entries.

### Group Related Capabilities Thoughtfully
Combine operations only when their inputs and outputs stay coherent. If the parameter list begins to diverge wildly or you find yourself adding an `operation` switch with disjoint argument sets, split the tool. The goal is to offer the model a clear, reusable schema rather than a catch-all interface that requires memorising mode-specific quirks.

### Preserve Clear Mental Models
Separate tools that represent fundamentally different intents or side effects—retrieving messages versus sending one, for example. This keeps the manifest scannable, helps the model choose safely, and reduces accidental misuse. Document the intent in the tool description so the LLM understands when to reach for each capability.

## References
- MCP specification: <https://spec.modelcontextprotocol.io>
- FastMCP Sidemap: <https://gofastmcp.com/llms.txt>
