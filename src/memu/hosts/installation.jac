import builtins;
import argparse;
import asyncio;
import contextlib;
import getpass;
import io;
import json;
import subprocess;
import sys;
import time;
import from collections.abc { Awaitable, Callable }
import from pathlib { Path }
import from typing { Any, TextIO }

class Blocked(Exception) {
    def __str__ -> str;
}

class Failed(Blocked) {}

async def backend(args: argparse.Namespace, invoke: Callable[[list[str]], Awaitable[int]]);
def _backend_inputs(args: argparse.Namespace, mode: str);
def _select_language(args: argparse.Namespace);
def _render_progress(result: dict[str, Any], output: TextIO, *, json_output: bool = False);
def _stop_reason(exc: BaseException, host: str) -> tuple[str, int, str];
async def run(
    args: argparse.Namespace,
    *,
    host: str,
    stages: tuple[str, ...],
    execute: Callable[[int, argparse.Namespace], Awaitable[None]],
    welcome: str,
    completion: dict[str, Any],
) -> int;
def add_arguments(parser: argparse.ArgumentParser, host: str, *, install_missing: bool = True);
def check_cleanup(home: Path, binary: str, instruction_name: str);
