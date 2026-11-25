import argparse;
import json;
import os;
import queue;
import re;
import shlex;
import shutil;
import subprocess;
import sys;
import tempfile;
import threading;
import time;
import from pathlib { Path }
import from typing { Any, Optional }

class AppServer {
    has stderr_thread: any,
        lines: queue.Queue[str | None],
        request_id: any,
        process: any;
    def init(executable: str, cwd: Path, codex_home: Path);
    def _read_stderr;
    def _read;
    def request(method: str, params: Optional[dict[str, Any]] = None) -> dict[str, Any];
    def notify(method: str);
    def close;
}

def _atomic_write(path: Path, data: bytes);
def _entries(value: Any, command: str, source: str) -> list[dict[str, Any]];
def _quote(value: str) -> str;
def _command(subcommand: str = "prompt-hook") -> str;
def _owns_command(command: str, subcommand: str = "prompt-hook") -> bool;
def _definition(groups: list[dict[str, Any]], command: str, subcommand: str = "prompt-hook");
def _trust(server: AppServer, listed: dict[str, Any], command: str, hooks_file: Path, cwd: Path);
def _trust_entry(server: AppServer, `entry: dict[str, Any]);
def install(
    codex: str,
    hooks_file: Path,
    cwd: Path,
    base_dir: str | None = None,
    *,
    default_home: bool = False,
);
async def _handle(args: argparse.Namespace) -> int;
def register(sub: Any);
