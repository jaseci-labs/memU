import argparse;
import json;
import os;
import sys;
import tempfile;
import from importlib.resources { files }
import from pathlib { Path }
import from typing { Any }
glob MARKER = "// memU managed retrieval extension.";
def agent_dir -> Path;
def target -> Path;
def extension_content(base: Path) -> str;
def install(base: Path) -> Path;
async def _install(args: argparse.Namespace) -> int;
async def _remove(args: argparse.Namespace) -> int;
def register(sub: Any);
