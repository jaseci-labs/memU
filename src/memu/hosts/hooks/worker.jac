import contextlib;
import json;
import os;
import signal;
import subprocess;
import sys;
import tempfile;
import threading;
import time;
import from collections.abc { Callable }
import from datetime { datetime }
import from pathlib { Path }
import from typing { TextIO }
def new_log_path(base: Path, hook: str = "memorize") -> Path;
def _copy_output(
    stream: TextIO | None,
    log: TextIO | None,
    errors: list[Exception],
    on_output: Callable[[str], None] | None,
);
def stream_agent(
    argv: list[str],
    layout: Layout,
    prompt: str,
    timeout: int,
    *,
    env: dict[str, str],
    on_output: Callable[[str], None] | None = None,
    stdin: int | None = None,
);
