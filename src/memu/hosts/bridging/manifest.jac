import hashlib;

import json;

import from collections.abc { Iterator }

import from pathlib { Path }

def _hash_file(path: Path) -> str;
def _iter_tracked(base_dir: Path, subdirs: list[str]) -> Generator[any, any, any];
def snapshot_tracked(base_dir: Path, subdirs: list[str], manifest_path: Path);
def diff_tracked(base_dir: Path, subdirs: list[str], manifest_path: Path) -> list[Path];
