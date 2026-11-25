import contextlib;
import errno;
import json;
import math;
import sys;
import time;
import from collections.abc { Iterator }
import from pathlib { Path }
@contextlib.contextmanager
def workspace_lock(base: Path) -> Iterator[bool];
glob COOLDOWN_SECONDS = 30 * 60;
@contextlib.contextmanager
def memorize_run(layout: Layout, *, cooldown_seconds: int = COOLDOWN_SECONDS) -> Iterator[bool];
