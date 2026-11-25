import argparse;
import json;
import os;
import shutil;
import subprocess;
import sys;
import urllib.error;
import urllib.request;
import from pathlib { Path }
import from typing { Any }
def _installation_directory -> Path;
def _desktop_binary(path: Path) -> bool;
def _discover(executable: str | None) -> Path | None;
def find_executable -> Path;
def _install;
def _probe(path: Path) -> dict[str, Any];
def prepare(executable: str | None = None, *, install_missing: bool = False) -> dict[str, Any];
async def _handle(args: argparse.Namespace) -> int;
def register(sub: Any);
