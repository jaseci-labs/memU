import from typing { Optional }
import os;
import shutil;
import subprocess;
import sys;
import tempfile;
import urllib.request;
import from pathlib { Path }
def configure_windows_path(executable: Path);
def install(host: str, url: str, *, unix_shell: str, env: Optional[dict[str, str]] = None);
