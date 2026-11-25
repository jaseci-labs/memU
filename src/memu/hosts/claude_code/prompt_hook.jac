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
glob LAYERS = ("hits", "resources"),
     CONTEXT_BUDGET = 9500;
def bounded_context(memories: dict[str, Any], trace: dict[str, Any]) -> str | None;
def _retrieve(trace: dict[str, Any]) -> dict[str, Any] | None;
async def _cmd_prompt_hook(args: argparse.Namespace) -> int;
def register(sub: Any);
