import json;
import os;
import re;
import subprocess;
import sys;
import tempfile;
import tomllib;
import from pathlib { Path }
import from typing { Any }
glob EXTRACT_THRESHOLD = query_extraction.EXTRACT_THRESHOLD,
     EXTRACT_TIMEOUT = query_extraction.EXTRACT_TIMEOUT;
def select_query(prompt: str, trace: dict[str, Any]) -> str;
def _https_options -> list[str];
def _extract(prompt: str) -> str;
def _run(argv: list[str], source: bytes, cwd: Path, flags: int);
