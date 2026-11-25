import operator;

import json;

import os;

import from collections.abc { Mapping }

import from pathlib { Path }

glob MAX_REMEMBERED: any = 1000,
     BRIDGING_RUN_ENV: any;

with entry {
    BRIDGING_RUN_ENV = "MEMU_BRIDGING_RUN";
}

def is_bridging_run(cwd: Path, base: Path, env: Mapping[str, str] | None = None) -> bool;
def load(path: Path) -> list[str];
def remember(path: Path, session_id: str) -> list[str];
