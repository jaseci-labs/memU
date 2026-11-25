import json;
import os;
import re;
import shutil;
import subprocess;
import sys;
import tempfile;
import time;
import from pathlib { Path }
import from typing { Any }
def standalone_env -> dict[str, str];
def _desktop_binary(path: Path) -> bool;
def find_executable(selected: str | None = None) -> Path;
def _install;
def prepare(selected: str | None = None, *, install_missing: bool = False) -> Path;
def _safe_response(message: str) -> str;
def verify_request(executable: Path);
def auth_status(executable: Path) -> bool;
