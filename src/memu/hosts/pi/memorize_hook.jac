import argparse;
import contextlib;
import json;
import os;
import shutil;
import subprocess;
import sys;
import traceback;
import from collections.abc { Iterator }
import from dataclasses { replace }
import from pathlib { Path }
import from typing { Any }
import from uuid { uuid4 }
@contextlib.contextmanager
def memorize_run(layout: Layout) -> Iterator[bool];
def stream_agent(argv: list[str], layout: Layout, prompt: str, timeout: int);
def launch_background(args: argparse.Namespace, event: dict[str, Any]) -> Path;
async def _cmd_memorize_hook(args: argparse.Namespace) -> int;
def register(sub: Any);
def main -> int;

with entry:__main__ {
    sys.exit(main());
}
