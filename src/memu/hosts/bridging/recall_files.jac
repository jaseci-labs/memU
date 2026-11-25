import contextlib;

import os;

import re;

import tempfile;

import from pathlib { Path }

import from typing { Any }
def _atomic_write_text(path: Path, text: str);
def recall_file_path(base_dir: Path, subdir: str, name: str) -> Path;
def write_recall_file(base_dir: Path, subdir: str, recall_file: dict[str, Any]) -> Path | None;
def read_recall_file(path: Path, track: str) -> dict[str, Any];
def finalize_recall_file(path: Path, recall_file: dict[str, Any]);
