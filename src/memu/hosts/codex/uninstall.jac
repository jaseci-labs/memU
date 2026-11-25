import builtins;
import argparse;
import json;
import re;
import tomllib;
import from pathlib { Path }
import from typing { Any }
def _owned(hook: dict[str, Any]) -> bool;
def _remove_definitions(config: dict[str, Any]) -> tuple[list[str], set[str]];
def uninstall(codex: str | None, cwd: Path) -> int;
def _offline_trust(original: bytes, path: Path) -> dict[str, str | None];
def _remap_trust(data: bytes, updates: dict[str, str | None]) -> bytes;
def _offline_uninstall(
    path: Path, original: bytes, config: dict[str, Any], removed: list[str]
) -> int;
def _trust_updates(
    before: dict[str, Any], after: dict[str, Any], commands: set[str], path: Path
) -> list[tuple[str, dict[str, Any]]];
def _apply_trust(
    server: hooks.AppServer, updates: list[tuple[str, dict[str, Any]]], path: Path, cwd: Path
);
async def _handle(args: argparse.Namespace) -> int;
def register(sub: Any);
