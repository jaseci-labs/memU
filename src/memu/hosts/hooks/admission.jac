import importlib;
import contextlib;
import errno;
import json;
import os;
import math;
import sys;
import time;
import from collections.abc { Iterator }
import from pathlib { Path }
glob _atomic_write_text: any;

with entry {
    _atomic_write_text = importlib.import_module(
        "memu.hosts.bridging.recall_files"
    )._atomic_write_text;
}

@contextlib.contextmanager
def workspace_lock(base: Path) -> Iterator[bool];
glob COOLDOWN_SECONDS = 30 * 60;
def _apply_env(values: dict[str, str | None]);
@contextlib.contextmanager
def memorize_run(
    layout: Layout,
    *,
    cooldown_seconds: int = COOLDOWN_SECONDS,
    env: dict[str, str | None] | None = None,
) -> Iterator[bool];
