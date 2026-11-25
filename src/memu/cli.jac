import argparse;
import asyncio;
import json;
import os;
import pathlib;
import re;
import shutil;
import sys;
import tempfile;
import time;
import from collections.abc { Callable, Coroutine }
import from typing { Any, Optional }
glob MEMORIZE_WORKSPACE = "~/.memu/developer",
     MAX_MEMORIZE_SESSIONS = 10;
def _env(name: str, `default: str) -> str;
def _add_common_options(parser: argparse.ArgumentParser);
def _build_backend(args: argparse.Namespace) -> any;
def _print_json(payload: Any);
async def _cmd_retrieve(args: argparse.Namespace) -> int;
async def _cmd_list_files(args: argparse.Namespace) -> int;
async def _cmd_commit(args: argparse.Namespace) -> int;
def _memorize_workspace(run_id: str | None = None) -> MemorizeWorkspace;
def _memorize_commit_command(run_id: str) -> str;
def _memorize_executor_prompt(prepared: PreparedMemorizeRun) -> str;
def _read_memorize_input(payload: str) -> MemorizeInput;
async def _cmd_memorize_prepare(args: argparse.Namespace) -> int;
async def _cmd_memorize_commit(args: argparse.Namespace) -> int;
async def _cmd_memorize_verify_resources(args: argparse.Namespace) -> int;
async def _cmd_memorize_discard(args: argparse.Namespace) -> int;
def build_parser -> argparse.ArgumentParser;
def main(argv: Optional[list[str]] = None) -> int;

with entry:__main__ {
    sys.exit(main());
}
