import argparse;
import asyncio;
import hashlib;
import json;
import sys;
import time;
import from datetime { UTC, datetime }
import from pathlib { Path }
import from typing { Any }
import from uuid { uuid4 }
async def _select_query(prompt: str, trace: dict[str, Any], event: dict[str, Any]) -> str;
async def prompt_hook(args: argparse.Namespace) -> int;
