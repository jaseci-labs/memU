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
import from typing { Any }
import from uuid { uuid4 }
glob select_query: any;

with entry {
    select_query = importlib.import_module("memu.hosts.codex.query_extraction").select_query;
}

async def _cmd_prompt_hook(args: argparse.Namespace) -> int;
def _retrieve(trace: dict[str, Any]);
def register(sub: Any);
