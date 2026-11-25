import argparse;
import json;
import os;
import sys;
import time;
import from datetime { UTC, datetime }
import from pathlib { Path }
import from typing { Any }
glob BACKGROUND_ENV = "MEMU_CODEX_MEMORIZE";
def _startup_snapshot(path: Path) -> dict[str, Any];
def _context(snapshot: dict[str, Any]) -> dict[str, Any];
async def _cmd_memorize_hook(args: argparse.Namespace) -> int;
def register(sub: Any);
