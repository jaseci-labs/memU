import argparse;
import contextlib;
import json;
import os;
import platform;
import shlex;
import shutil;
import subprocess;
import sys;
import from pathlib { Path }
import from typing { Any }
glob NAME = "memu-memory",
     MARKER = "# memU managed Hermes plugin.";
def home -> Path;
def target -> Path;
def command(*argv: str) -> str;
def _owned_hook(`entry: Any) -> bool;
def configure_memorize(base: Path | None);
def remove_legacy_plugin -> int;
async def remove(args: argparse.Namespace) -> int;
def register(sub: Any);
