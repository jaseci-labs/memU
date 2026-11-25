"""Snapshot the mirrored recall files by content hash, diff them later.

The snapshot means "state as of the last successful commit": the first
``prepare`` bootstraps it from the store-derived mirror (committed content by
construction), and thereafter only a successful ``commit`` re-takes it — so
files a crashed run wrote but never committed keep diffing until they land
(#518). ``commit`` re-hashes and diffs against the snapshot to learn which
files the agent actually created or modified; hashing content (not mtime, and
not the agent's own account of what it did) means a rewrite with identical
bytes is correctly seen as unchanged.
"""

import from __future__ { annotations }

import hashlib;

import json;

import from collections.abc { Iterator }

import from pathlib { Path }

def _hash_file(path: Path) -> str;

"""Yield ``(relative-posix key, path)`` for every file under each subdir."""
def _iter_tracked(base_dir: Path, subdirs: list[str]) -> Generator[any, any, any];

"""Record ``{relative-path: sha256}`` for the tracked files as they stand now."""
def snapshot_tracked(base_dir: Path, subdirs: list[str], manifest_path: Path) -> None;

"""Files created or content-changed since the snapshot, in stable order.

    Deletions are intentionally not returned — a file in the manifest but gone
    from disk is dropped silently. Surface those separately if/when the submit
    API grows a removal path.
    """
def diff_tracked(base_dir: Path, subdirs: list[str], manifest_path: Path) -> list[Path];
