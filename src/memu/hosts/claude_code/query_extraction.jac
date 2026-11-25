import json;
import subprocess;
import tempfile;
import from pathlib { Path }
import from typing { Any }
def select_query(prompt: str, trace: dict[str, Any]) -> str;
def _extract(prompt: str) -> str;
