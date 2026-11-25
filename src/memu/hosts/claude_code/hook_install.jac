import builtins;
import json;
import shlex;
import shutil;
import sys;
import from pathlib { Path }
import from typing { Any }
glob SUBCOMMANDS = ("prompt-hook", "memorize-hook");
def home -> Path;
def read -> tuple[Path, bytes | None, dict[str, Any]];
def owns(hook: dict[str, Any], subcommand: str) -> bool;
def definitions(base: Path) -> list[dict[str, Any]];
def _write(path: Path, original: bytes | None, data: dict[str, Any]);
def install(base: Path);
def uninstall -> int;
def problems -> list[str];
