import importlib;
import argparse;
import hashlib;
import json;
import os;
import subprocess;
import sys;
import time;
import from datetime { UTC, datetime }
import from pathlib { Path }
import from typing { Any, Optional }
import from uuid { uuid4 }
glob select_query: any;

with entry {
    select_query = importlib.import_module("memu.hosts.claude_code.query_extraction").select_query;
}

glob LAYERS = ("hits", "resources"),
     CONTEXT_BUDGET = 9500;
def bounded_context(memories: dict[str, Any], trace: dict[str, Any]) -> str | None;
def _retrieve(trace: dict[str, Any]) -> Optional[dict[str, Any]];
async def _cmd_prompt_hook(args: argparse.Namespace) -> int;
def register(sub: Any);
