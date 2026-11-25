import hashlib;
import math;
import os;
import re;
import time;
import urllib.request;
import from collections.abc { Iterable }
import from pathlib { Path }
glob DEFAULT_BASE_URL = "https://memu.pro/sdk/instructions",
     MEMORY_JOB = "memory-job",
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

def _base_url -> str | None {
    value = os.environ.get("MEMU_TEMPLATE_BASE_URL", DEFAULT_BASE_URL);
    return value or None;
}

def _cache_dir -> Path {
    return Path(os.path.expanduser(BASE_DIR)) / "cache" / "instructions";
}

def _valid(text: str, required_keys: Iterable[str]) -> bool {
    if not text.strip() {
        return False;
    }
    if any(("{" + key not in text for key in required_keys)) {
        return False;
    }
    try {
        text.format(**dict.fromkeys(required_keys, ""));
    } except (KeyError, IndexError, ValueError) {
        return False;
    }
    return True;
}

def _get(url: str) -> str | None {
    try {
        with urllib.request.urlopen(
            url, timeout=_TIMEOUT_SECONDS, **trust.urlopen_kwargs()
        ) as resp {
            if getattr(resp, "status", 200) != 200 {
                return None;
            }
            raw: bytes = resp.read(_MAX_BYTES + 1);
        }
    } except Exception {
        return None;
    }
    if len(raw) > _MAX_BYTES {
        return None;
    }
    try {
        return raw.decode("utf-8");
    } except UnicodeDecodeError {
        return None;
    }
}

def fetch(name: str) -> str | None {
    base = _base_url();
    if base is None {
        return None;
    }
    text = _get(f"{base}/{name}.txt");
    if text is None or not _valid(text, REQUIRED_KEYS[name]) {
        return None;
    }
    _write_cache(_cache_dir() / f"{name}.txt", text);
    return text;
}

def _write_cache(path: Path, text: str) -> bool {
    try {
        path.parent.mkdir(parents=True, exist_ok=True);
        tmp = path.with_suffix(".txt.tmp");
        tmp.write_text(text, encoding="utf-8");
        os.replace(tmp, path);
    } except OSError {
        return False;
    }
    return True;
}

def _read_cache(path: Path, name: str) -> str | None {
    try {
        text = path.read_text(encoding="utf-8");
    } except (OSError, UnicodeError) {
        return None;
    }
    return text if _valid(text, REQUIRED_KEYS[name]) else None;
}

def _refresh_due(attempt_path: Path, now: float) -> bool {
    try {
        last_attempt = float(attempt_path.read_text(encoding="utf-8"));
    } except (OSError, ValueError) {
        return True;
    }
    return True
        if not math.isfinite(last_attempt) or last_attempt > now
        else now - last_attempt >= _REFRESH_INTERVAL_SECONDS;
}

def resolve(name: str, embedded: str) -> str {
    base = _base_url();
    if base is None {
        return embedded;
    }
    url = f"{base}/{name}.txt";
    url_key = hashlib.sha256(url.encode()).hexdigest();
    cache_path = _cache_dir() / f"template-{url_key}.txt";
    attempt_path = _cache_dir() / f"attempt-{url_key}.txt";
    now = time.time();
    if _refresh_due(attempt_path, now) {
        remote = _get(url);
        if remote is not None and _valid(remote, REQUIRED_KEYS[name]) {
            if _write_cache(cache_path, remote) {
                _write_cache(attempt_path, str(now));
            }
            return remote;
        }
        _write_cache(attempt_path, str(now));
    }
    return _read_cache(cache_path, name) or embedded;
}

glob DEFAULT_DOCS_BASE_URL = "https://memu.pro/sdk/docs";

def _docs_base_url -> str | None {
    value = os.environ.get("MEMU_DOCS_BASE_URL", DEFAULT_DOCS_BASE_URL);
    return value or None;
}

def _docs_cache_dir(host: str) -> Path {
    return Path(os.path.expanduser(BASE_DIR)) / "cache" / "docs" / host;
}

glob DOC_REQUIRED_TOKENS = frozenset({"task_name", "former_task_names", "all_task_names"}),
     _DOC_TOKEN_RE = re.compile("\\{\\{([a-z_]+)\\}\\}"),
     _DOC_ALLOWED_TOKENS = DOC_REQUIRED_TOKENS | {"task_doc_name", "task_name_pattern"};

def _valid_doc(text: str) -> bool {
    if not text.strip() {
        return False;
    }
    matches = list(_DOC_TOKEN_RE.finditer(text));
    tokens: set[str] = {str(`match.group(1)) for `match in matches};
    if not DOC_REQUIRED_TOKENS.issubset(tokens) or not tokens.issubset(_DOC_ALLOWED_TOKENS) {
        return False;
    }
    stripped = _DOC_TOKEN_RE.sub("", text);
    return "{{" not in stripped and "}}" not in stripped;
}

def _valid_host_doc(host: str, filename: str, text: str) -> bool {
    if not _valid_doc(text) {
        return False;
    }
    if filename == "UNINSTALL.md" and "<!-- memu-cleanup: owned-artifacts -->" not in text {
        return False;
    }
    if host == "codex" and filename in {"INSTALL.md", "UNINSTALL.md"} {
        if "<!-- memu-codex-record: submit-v1 -->" not in text {
            return False;
        }
        if filename == "INSTALL.md" {
            return "<!-- memu-codex-permissions: v22 -->" in text
                and "<!-- memu-codex-install: cli-v2 -->" in text;
        }
    }
    if host == "claude-code" and filename in {"INSTALL.md", "UNINSTALL.md"} {
        return "<!-- memu-claude-install: cli-v1 -->" in text;
    }
    if host == "hermes" and filename in {"INSTALL.md", "UNINSTALL.md"} {
        return "<!-- memu-hermes-install: soul-v1 -->" in text;
    }
    if host == "pi" and filename in {"INSTALL.md", "UNINSTALL.md"} {
        return "<!-- memu-pi-install: extension-v1 -->" in text;
    }
    return True;
}

def fetch_doc(host: str, filename: str) -> str | None {
    base = _docs_base_url();
    if base is None {
        return None;
    }
    text = _get(f"{base}/{host}/{filename}");
    if text is None or not _valid_host_doc(host, filename, text) {
        return None;
    }
    _write_doc_cache(host, filename, text);
    return text;
}

def _write_doc_cache(host: str, filename: str, text: str) {
    try {
        cache_dir = _docs_cache_dir(host);
        cache_dir.mkdir(parents=True, exist_ok=True);
        tmp = cache_dir / f"{filename}.tmp";
        tmp.write_text(text, encoding="utf-8");
        os.replace(tmp, cache_dir / filename);
    } except OSError {}
}

def _read_doc_cache(host: str, filename: str) -> str | None {
    try {
        text = (_docs_cache_dir(host) / filename).read_text(encoding="utf-8");
    } except OSError {
        return None;
    }
    return text if _valid_host_doc(host, filename, text) else None;
}

def resolve_doc(host: str, filename: str, embedded: str) -> str {
    return embedded
        if not embedded.strip()
        else fetch_doc(host, filename) or _read_doc_cache(host, filename) or embedded;
}
