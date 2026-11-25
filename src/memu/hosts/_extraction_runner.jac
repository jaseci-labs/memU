"""Run one query-extraction CLI on Windows, Linux, and macOS using only stdlib.

The caller supplies an ASCII JSON argv line followed by the extractor's raw
stdin. On Linux/macOS, a lifetime pipe monitors the calling hook. This runner
kills the extractor's process group when the hook or extractor exits;
descendants that leave that group are outside this cleanup boundary.

On Windows, the caller assigns this gated runner to a kill-on-close Job Object
before sending the command. The Job owns the runner and its descendants.
"""

import operator;

import from jaclang.comptime { target }

import from __future__ { annotations }

import errno;

import json;

import os;

import select;

import signal;

import subprocess;

import sys;

import from contextlib { suppress }

def _owner_exited(lifetime_fd: int, timeout: float = 0) -> bool;

def _read_command(lifetime_fd: int) -> list[str] | None;

def _group_has_only_zombies(group_id: int) -> bool;

comptime if target().os == "darwin" {
    def _wait_darwin(process_id: int, lifetime_fd: int) -> None;
}

def _wait_posix(process: subprocess.Popen[bytes], lifetime_fd: int) -> int;

def _run(lifetime_fd: int, flags: int) -> dict[str, int | str | None];

def main -> None;

with entry:__main__ {
    main();
}
