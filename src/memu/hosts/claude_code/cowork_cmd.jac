import builtins;
import argparse;
import hashlib;
import json;
import os;
import sys;
import from dataclasses { dataclass }
import from enum { IntEnum }
import from itertools { pairwise }
import from pathlib { Path }
import from typing { Any }

class _Status(IntEnum) {
    static has PASS: any = 0,
               WARN: any = 1,
               FAIL: any = 2;
}

@dataclass(frozen=True)
class _Check {
    has name: str,
        status: _Status,
        rows: tuple[tuple[str, object], ...];
}

@dataclass(frozen=True)
class _Fingerprints {
    has messages: int,
        skipped: int,
        values: frozenset[bytes];
}

def _directory(value: str) -> Path;
def _fingerprints(
    source: TranscriptSource, records_by_path: dict[Path, list[str]]
) -> _Fingerprints;
def _read_all(source: TranscriptSource, paths: list[Path]) -> tuple[dict[Path, list[str]], int];
def _root_counts(source: CoworkTranscriptSource, paths: list[Path]) -> list[tuple[Path, int]];
def _readable_check(
    source: CoworkTranscriptSource,
    paths: list[Path],
    records: dict[Path, list[str]],
    errors: int,
    fingerprints: _Fingerprints,
) -> _Check;
def _separation_check(
    code: ClaudeCodeTranscriptSource,
    cowork: CoworkTranscriptSource,
    code_paths: list[Path],
    cowork_paths: list[Path],
    code_errors: int,
    cowork_errors: int,
    code_fingerprints: _Fingerprints,
    cowork_fingerprints: _Fingerprints,
) -> _Check;
def _timeline_check(
    source: ClaudeDesktopTranscriptSource,
    code_paths: list[Path],
    cowork_paths: list[Path],
    roots: tuple[Path, ...],
) -> _Check;
def _render(
    *,
    mode: str,
    cowork: CoworkTranscriptSource,
    cowork_paths: list[Path],
    checks: tuple[_Check, ...],
);
async def _cmd_verify(args: argparse.Namespace) -> int;
def register(sub: Any);
