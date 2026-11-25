import builtins;
import argparse;
import getpass;
import subprocess;
import from pathlib { Path }
import from typing { Any }
import from urllib.parse { urlsplit }
def _provider;
def configure(executable: Path, *, method: str | None, non_interactive: bool);
async def run(args: argparse.Namespace) -> int;
def register(sub: Any);
