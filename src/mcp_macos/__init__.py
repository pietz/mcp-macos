from __future__ import annotations

import asyncio
import logging

from fastmcp import FastMCP

from .tools import mail_server

logger = logging.getLogger(__name__)

hub = FastMCP("macOS Control")


async def _register_modules() -> None:
    await hub.import_server(mail_server, prefix="mail")


def main() -> None:
    """Entry point for running the MCP server hub."""

    logging.basicConfig(level=logging.INFO)

    logger.info("Registering MCP sub-servers")
    asyncio.run(_register_modules())

    logger.info("Starting FastMCP hub")
    hub.run()
