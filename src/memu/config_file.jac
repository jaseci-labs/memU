import contextlib;
import os;
import tempfile;
import from collections.abc { Mapping }
import from pathlib { Path }
def config_path -> Path;
def read -> dict[str, str];
def write_values(updates: Mapping[str, str], *, comments: str = "") -> tuple[Path, bool];
def permission_note -> str;
def _split(raw: str) -> tuple[str, str];
def _merged(text: str, updates: dict[str, str]) -> str;
def _restrict(path: Path);
