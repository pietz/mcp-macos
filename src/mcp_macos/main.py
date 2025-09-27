import asyncio
from fastmcp import FastMCP
from .servers.mail import mcp as mail_mcp
from .servers.calendar import mcp as cal_mcp

main = FastMCP("macos-appleapps")


async def setup() -> None:
    await main.import_server(mail_mcp, prefix="mail")
    # await main.import_server(cal_mcp, prefix="cal")


def cli() -> None:
    asyncio.run(setup())
    main.run()


if __name__ == "__main__":
    cli()
