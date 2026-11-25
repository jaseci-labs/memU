import importlib;
import argparse;
import contextlib;
import json;
import os;
import shutil;
import subprocess;
import sys;
import traceback;
import from collections.abc { Iterator }
import from pathlib { Path }
import from typing { Any }
@contextlib.contextmanager
def memorize_run(layout: Layout) -> Iterator[bool];
def launch(base: Path, session_id: str) -> Path;
async def handle(args: argparse.Namespace) -> int;
def register(sub: Any);
def main -> int;

with entry:__main__ {
    sys.exit(main());
}
