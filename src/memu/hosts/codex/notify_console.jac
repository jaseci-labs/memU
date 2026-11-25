import builtins;
import argparse;
import contextlib;
import io;
import json;
import os;
import shlex;
import shutil;
import subprocess;
import sys;
import time;
import traceback;
import from collections.abc { Iterator }
import from pathlib { Path }
import from typing { TextIO, cast }
import from uuid { UUID }

class _Tee(io.TextIOBase) {
    has log: TextIO,
        terminal: TextIO;
    def init(terminal: TextIO, log: TextIO);

    has name: str {
        getter {
            return str(self.log.name);
        }
    }

    def write(text: str) -> int;
    def flush;
}

def launch_background(argv: list[str], layout: Layout, label: str) -> Path;
def launch(argv: list[str], layout: Layout, label: str, hold: bool);
def _new_log_path(base: Path, hook: str = "memorize") -> Path;
def _remember_thread(line: str, layout: Layout);
def stream_agent(argv: list[str], layout: Layout, prompt: str, timeout: int);
glob COOLDOWN_SECONDS = 30 * 60,
     _workspace_lock = admission.workspace_lock;
@contextlib.contextmanager
def memorize_run(layout: Layout) -> Iterator[bool];
def main -> int;

with entry:__main__ {
    sys.exit(main());
}
