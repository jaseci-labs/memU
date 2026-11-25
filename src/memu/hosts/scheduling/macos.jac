import json;
import os;
import plistlib;
import re;
import shlex;
import stat;
import subprocess;
import sys;
import tempfile;
import from dataclasses { dataclass }
import from pathlib { Path }

@dataclass(frozen=True)
class Registration {
    has source: str,
        kind: str,
        original: bytes,
        path: Path | None = None,
        domains: tuple[str, ...] = (),
        label: str = "",
        user: str | None = None,
        retained: bytes = b'';
}

def _run(argv: list[str], *, data: bytes | None = None) -> subprocess.CompletedProcess[bytes];
def _checked(argv: list[str], *, data: bytes | None = None) -> bytes;
def _is_bridge(argv: list[str]) -> bool;
def _related(text: str) -> bool;
def _read_file(path: Path) -> bytes;
def _locations -> list[tuple[Path, tuple[str, ...]]];
def _cron_users -> tuple[str | None, ...];
def _system_crontab -> Path;
def _read_cron(user: str | None) -> bytes;
def _select_cron(data: bytes, *, system: bool = False) -> tuple[bytes, int, list[str]];
def _plist_registration(path: Path, domains: tuple[str, ...]) -> Registration | None;
def _inspect_launchd -> tuple[list[Registration], list[str]];
def _inspect_system_cron -> tuple[list[Registration], list[str]];
def inspect -> tuple[list[Registration], list[str]];
def _job(target: str) -> bytes | None;
def _unload(target: str);
def _remove_launchd(item: Registration);
def _replace_cron_file(item: Registration);
def _remove_cron(item: Registration);
def _describe(item: Registration) -> dict[str, object];
def cleanup(*, remove: bool = False) -> int;
