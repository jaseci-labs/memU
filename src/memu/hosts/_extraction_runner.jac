import from typing { Optional }
import operator;

import from jaclang.comptime { target }

import errno;

import json;

import os;

import select;

import signal;

import subprocess;

import sys;

import from contextlib { suppress }

def _owner_exited(lifetime_fd: int, timeout: float = 0) -> bool;

def _read_command(lifetime_fd: int) -> Optional[list[str]];

def _group_has_only_zombies(group_id: int) -> bool;

comptime if target().os == "darwin" {
    def _wait_darwin(process_id: int, lifetime_fd: int) -> None;
}

def _wait_posix(process: subprocess.Popen[bytes], lifetime_fd: int) -> int;

def _run(lifetime_fd: int, flags: int) -> dict[str, int | str | None];

def main;

with entry:__main__ {
    main();
}
