import hashlib;
import math;
import os;
import re;
import time;
import urllib.request;
import from collections.abc { Iterable }
import from pathlib { Path }
glob DEFAULT_BASE_URL = "https://memu.pro/sdk/instructions";

with entry {}

glob MEMORY_JOB = "memory-job",
     SKILL_JOB = "skill-job",
     RESOURCE_JOB = "resource-job",
     RETRIEVAL_SKILL = "retrieval-skill",
     REQUIRED_KEYS: dict[str, frozenset[str]] = {
         MEMORY_JOB: frozenset({"input_path", "track_dir"}),
         SKILL_JOB: frozenset({"input_path", "track_dir", "resource_log"}),
         RESOURCE_JOB: frozenset({"verify_command", "resource_file"}),
         RETRIEVAL_SKILL: frozenset({"binary"}),
     },
     _TIMEOUT_SECONDS = 4.0,
     _REFRESH_INTERVAL_SECONDS = 24 * 60 * 60,
     _MAX_BYTES = 64 * 1024;
def _base_url -> str | None;
def _cache_dir -> Path;
def _valid(text: str, required_keys: Iterable[str]) -> bool;
def _get(url: str) -> str | None;
def fetch(name: str) -> str | None;
def _write_cache(path: Path, text: str) -> bool;
def _read_cache(path: Path, name: str) -> str | None;
def _refresh_due(attempt_path: Path, now: float) -> bool;
def resolve(name: str, embedded: str) -> str;
glob DEFAULT_DOCS_BASE_URL = "https://memu.pro/sdk/docs";

with entry {}

def _docs_base_url -> str | None;
def _docs_cache_dir(host: str) -> Path;
glob DOC_REQUIRED_TOKENS = frozenset({"task_name", "former_task_names", "all_task_names"}),
     _DOC_TOKEN_RE = re.compile("\\{\\{([a-z_]+)\\}\\}"),
     _DOC_ALLOWED_TOKENS = DOC_REQUIRED_TOKENS | {"task_doc_name", "task_name_pattern"};
def _valid_doc(text: str) -> bool;
def _valid_host_doc(host: str, filename: str, text: str) -> bool;
def fetch_doc(host: str, filename: str) -> str | None;
def _write_doc_cache(host: str, filename: str, text: str);
def _read_doc_cache(host: str, filename: str) -> str | None;
def resolve_doc(host: str, filename: str, embedded: str) -> str;
