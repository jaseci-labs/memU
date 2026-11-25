import importlib;
import contextlib;
import hashlib;
import json;
import os;
import platform;
import sys;
import time;
import traceback;
import urllib.error;
import urllib.request;
import uuid;
import from collections.abc { Iterable }
import from datetime { UTC, datetime }
import from pathlib { Path }
import from typing { Any, Optional }
glob DEFAULT_EVENTS_URL = "https://api.memu.so/api/memu/analytics/events",
     MEMORY_SEARCH_SUCCEEDED = "memory_search_succeeded",
     MEMORY_SEARCH_FAILED = "memory_search_failed",
     MEMORY_LIST_SUCCEEDED = "memory_list_succeeded",
     MEMORY_LIST_FAILED = "memory_list_failed",
     MEMORY_COMMIT_SUCCEEDED = "memory_commit_succeeded",
     MEMORY_COMMIT_FAILED = "memory_commit_failed",
     MEMORY_UPDATE_STARTED = "memory_update_started",
     MEMORY_UPDATE_SUCCEEDED = "memory_update_succeeded",
     MEMORY_UPDATE_FAILED = "memory_update_failed",
     CLI_INSTALL_STARTED = "cli_install_started",
     INSTALL_GUIDE_OPENED = "install_guide_opened",
     CLI_INSTALL_SUCCEEDED = "cli_install_succeeded",
     CLI_INSTALL_FAILED = "cli_install_failed",
     UNINSTALL_GUIDE_OPENED = "uninstall_guide_opened",
     CLI_UNINSTALL_SUCCEEDED = "cli_uninstall_succeeded",
     CLI_UNINSTALL_FAILED = "cli_uninstall_failed",
     AGENT_ERROR_REPORTED = "agent_error_reported",
     CLI_ERROR = "cli_error",
     CLI_EVENTS_DROPPED = "cli_events_dropped",
     CLIENT_TYPE = "memu_cli",
     SPOOL_PATH = "~/.memu/events.jsonl",
     MAX_SPOOL_BYTES = 1024 * 1024,
     MAX_FLUSH_POSTS = 200,
     MAX_DETAIL_CHARS = 5000,
     MAX_FRAMES = 20,
     ERROR_DEDUP_SECONDS = 3600.0,
     MAX_LEDGER_ENTRIES = 200,
     _TIMEOUT_SECONDS = 5.0,
     STAGES: tuple[str, ...] = ("install", "uninstall", "remember", "retrieve", "other"),
     _READ_COUNTS = frozenset({"result_count", "latency_ms"}),
     _WRITE_COUNTS = frozenset({"recall_file_count", "resource_count", "session_count"}),
     _ALLOWED_PROPERTIES: dict[str, frozenset[str]] = {
         MEMORY_SEARCH_SUCCEEDED: _READ_COUNTS,
         MEMORY_SEARCH_FAILED: _READ_COUNTS,
         MEMORY_LIST_SUCCEEDED: _READ_COUNTS,
         MEMORY_LIST_FAILED: _READ_COUNTS,
         MEMORY_COMMIT_SUCCEEDED: _WRITE_COUNTS | {"latency_ms"},
         MEMORY_COMMIT_FAILED: _WRITE_COUNTS | {"latency_ms"},
         MEMORY_UPDATE_SUCCEEDED: _WRITE_COUNTS | {"duration_ms"},
         MEMORY_UPDATE_STARTED: frozenset(),
         MEMORY_UPDATE_FAILED: frozenset(),
         CLI_INSTALL_STARTED: frozenset(),
         INSTALL_GUIDE_OPENED: frozenset(),
         CLI_INSTALL_SUCCEEDED: frozenset(),
         CLI_INSTALL_FAILED: frozenset(),
         UNINSTALL_GUIDE_OPENED: frozenset(),
         CLI_UNINSTALL_SUCCEEDED: frozenset(),
         CLI_UNINSTALL_FAILED: frozenset(),
         AGENT_ERROR_REPORTED: frozenset({"stage", "detail"}),
         CLI_ERROR: frozenset({"command", "error_type", "frames", "frames_truncated"}),
         CLI_EVENTS_DROPPED: frozenset({"dropped_count"}),
     },
     REPORTED_BY_CODE = "code",
     REPORTED_BY_AGENT = "agent",
     _AGENT_REPORTED: frozenset[str] = frozenset({
         CLI_INSTALL_SUCCEEDED,
         CLI_INSTALL_FAILED,
         CLI_UNINSTALL_SUCCEEDED,
         CLI_UNINSTALL_FAILED,
         MEMORY_UPDATE_FAILED,
         AGENT_ERROR_REPORTED,
     }),
     STAGE_FAILURE_EVENTS: dict[str, str] = {
         "install": CLI_INSTALL_FAILED,
         "uninstall": CLI_UNINSTALL_FAILED,
         "remember": MEMORY_UPDATE_FAILED,
     },
     AGENT_PLATFORMS: dict[str, str] = {"claude-code": "claude_code"};

def _off(value: str | None) -> bool {
    return (value or "").strip().lower() in {"0", "false", "no", "off"};
}

def _on(value: str | None) -> bool {
    return (value or "").strip().lower() in {"1", "true", "yes", "on"};
}

def events_url -> str | None {
    return env_declared("MEMU_EVENTS_BASE_URL", DEFAULT_EVENTS_URL) or None;
}

def enabled -> bool {
    if _off(env_declared("MEMU_TELEMETRY", "1")) {
        return False;
    }
    return False if _on(os.environ.get("DO_NOT_TRACK")) else events_url() is not None;
}

def _spool_path -> Path {
    return Path(os.path.expanduser(env("MEMU_EVENTS_SPOOL", SPOOL_PATH) or SPOOL_PATH));
}

def client_version -> str {
    __version__ = importlib.import_module("memu").__version__;
    return __version__;
}

def client_instance_id -> str {
    existing = env("MEMU_CLIENT_ID");
    if existing {
        return existing;
    }
    generated = str(uuid.uuid4());
    try {
        config_file.write_values({"MEMU_CLIENT_ID": generated});
    } except OSError {
        return generated;
    }
    reload();
    return env("MEMU_CLIENT_ID") or generated;
}

def reported_by(event_name: str) -> str {
    return REPORTED_BY_AGENT if event_name in _AGENT_REPORTED else REPORTED_BY_CODE;
}

def agent_platform(host: str | None) -> str {
    return "none" if not host else AGENT_PLATFORMS.get(host, host.replace("-", "_"));
}

def _os_name -> str {
    return {"Darwin": "macos", "Windows": "windows", "Linux": "linux"}.get(
        platform.system(), "other"
    );
}

def _now -> str {
    now = datetime.now(UTC);
    return f"{now.strftime('%Y-%m-%dT%H:%M:%S')}.{now.microsecond // 1000:03d}Z";
}

def _session_id(session_id_env: str) -> str {
    return "" if not session_id_env else os.environ.get(session_id_env, "").strip();
}

def envelope(
    event_name: str,
    *,
    host: str = "",
    session_id_env: str = "",
    properties: Optional[dict[str, Any]] = None,
) -> dict[str, Any] {
    built: dict[str, Any] = {
        "event_id": str(uuid.uuid4()),
        "event_name": event_name,
        "client_type": CLIENT_TYPE,
        "client_instance_id": client_instance_id(),
        "occurred_at": _now(),
        "context": {
            "client_version": client_version(),
            "agent_platform": agent_platform(host),
            "os": _os_name(),
            "deployment_mode": memory_mode(),
            "reported_by": reported_by(event_name),
        },
        "properties": _filter(event_name, properties),
    };
    session_id = _session_id(session_id_env);
    if session_id {
        built["context"]["session_id"] = session_id;
    }
    return built;
}

def record(
    event_name: str,
    *,
    host: str = "",
    session_id_env: str = "",
    properties: Optional[dict[str, Any]] = None,
    deliver: bool = False,
) {
    try {
        if not enabled() {
            return;
        }
        built = envelope(
            event_name, host=host, session_id_env=session_id_env, properties=properties
        );
        if deliver and _deliver(built) {
            return;
        }
        _append(json.dumps(built, ensure_ascii=False, default=str));
    } except Exception {
        return;
    }
}

def _deliver(event: dict[str, Any]) -> bool {
    url = events_url();
    return False if url is None else _post(url, event) != RETRY;
}

def _filter(event_name: str, properties: Optional[dict[str, Any]]) -> dict[str, Any] {
    allowed = _ALLOWED_PROPERTIES.get(event_name, frozenset());
    return {key: value for (key, value) in (properties or {}).items() if key in allowed};
}

def _append(line: str) {
    path = _spool_path();
    try {
        path.parent.mkdir(parents=True, exist_ok=True);
        if path.is_file() and path.stat().st_size >= MAX_SPOOL_BYTES {
            _count_drop();
            return;
        }
        with open(path, "a", encoding="utf-8") as handle {
            handle.write(line + "\n");
        }
    } except OSError {}
}

def _drop_counter -> Path {
    return _spool_path().with_suffix(".dropped");
}

def _count_drop {
    counter = _drop_counter();
    try {
        previous = int(counter.read_text(encoding="utf-8").strip()) if counter.is_file() else 0;
    } except (OSError, ValueError) {
        previous = 0;
    }
    with contextlib.suppress(OSError) {
        counter.write_text(str(previous + 1), encoding="utf-8");
    }
}

def record_outcome(
    succeeded: str,
    failed: str,
    *,
    host: str = "",
    session_id_env: str = "",
    success: bool,
    deliver: bool = False,
    **counts: Any,
) {
    record(
        succeeded if success else failed,
        host=host,
        session_id_env=session_id_env,
        properties=counts,
        deliver=deliver,
    );
}

def record_list(
    *, started: float, listed: int, success: bool, host: str = "", session_id_env: str = ""
) {
    record_outcome(
        MEMORY_LIST_SUCCEEDED,
        MEMORY_LIST_FAILED,
        host=host,
        session_id_env=session_id_env,
        success=success,
        result_count=listed,
        latency_ms=round((time.monotonic() - started) * 1000),
    );
}

def record_agent_error(*, stage: str, detail: str = "", host: str = "", session_id_env: str = "") {
    try {
        if not enabled() {
            return;
        }
        clipped = detail.strip()[:MAX_DETAIL_CHARS];
        if not _claim_error(stage, clipped) {
            return;
        }
        record(
            AGENT_ERROR_REPORTED,
            host=host,
            session_id_env=session_id_env,
            properties={"stage": stage, "detail": clipped},
        );
        concrete = STAGE_FAILURE_EVENTS.get(stage);
        if concrete {
            record(concrete, host=host, session_id_env=session_id_env);
        }
    } except Exception {
        return;
    }
}

def _error_ledger -> Path {
    return _spool_path().with_suffix(".errors");
}

def _claim_error(stage: str, detail: str) -> bool {
    ledger = _error_ledger();
    fingerprint = hashlib.sha256(f"{stage}\u0000{detail}".encode()).hexdigest()[:16];
    now = datetime.now(UTC).timestamp();
    kept = [`entry for `entry in _read(ledger) if now - _stamp(`entry) < ERROR_DEDUP_SECONDS];
    if any((`entry.get("fingerprint") == fingerprint for `entry in kept)) {
        return False;
    }
    _retain(ledger, [*kept[-(MAX_LEDGER_ENTRIES - 1):], {"fingerprint": fingerprint, "at": now}]);
    return True;
}

def _stamp(`entry: dict[str, Any]) -> float {
    at = `entry.get("at");
    return float(at) if isinstance(at, (int, float)) else 0.0;
}

def record_cli_error(
    exc: BaseException, *, command: str = "", host: str = "", session_id_env: str = ""
) {
    try {
        frames = _frames(exc);
        record(
            CLI_ERROR,
            host=host,
            session_id_env=session_id_env,
            properties={
                "command": command,
                "error_type": type(exc).__name__,
                "frames": frames[-MAX_FRAMES:],
                "frames_truncated": len(frames) > MAX_FRAMES,
            },
        );
    } except Exception {
        return;
    }
}

def _frames(exc: BaseException) -> list[str] {
    labels: list[str] = [];
    for frame in traceback.extract_tb(exc.__traceback__) {
        labels.append(f"{_module_of(frame.filename)}:{frame.name}:{frame.lineno}");
    }
    return labels;
}

def _module_of(filename: str) -> str {
    parts = Path(filename).with_suffix("").parts;
    if "memu" not in parts {
        return "<external>";
    }
    start = len(parts) - 1 - parts[::-1].index("memu");
    return ".".join(parts[start:]);
}

def flush -> tuple[int, int] {
    try {
        return _flush();
    } except Exception {
        return (0, 0);
    }
}

def _flush -> tuple[int, int] {
    if not enabled() {
        return (0, 0);
    }
    url = events_url();
    if url is None {
        return (0, 0);
    }
    _promote_drop_counter();
    rejected = 0;
    accepted = rejected;
    posts_left = MAX_FLUSH_POSTS;
    pending = _sending_files();
    rotated_live = False;
    if not pending {
        pending = _rotate_spool();
        rotated_live = True;
    }
    path_index = 0;
    while path_index < len(pending) {
        path = pending[path_index];
        (sent, refused, posts_left, retained) = _drain(path, url, posts_left);
        accepted += sent;
        rejected += refused;
        if retained is not None {
            _retain(path, retained);
            break;
        }
        _unlink(path);
        path_index += 1;
        if path_index == len(pending) and (not rotated_live) and (posts_left > 0) {
            pending.extend(_rotate_spool());
            rotated_live = True;
        }
    }
    return (accepted, rejected);
}

def _drain(
    path: Path, url: str, posts_left: int
) -> tuple[int, int, int, Optional[list[dict[str, Any]]]] {
    events = _read(path);
    event_index = 0;
    rejected = 0;
    accepted = rejected;
    stalled = False;
    while event_index < len(events) {
        if posts_left <= 0 {
            stalled = True;
            break;
        }
        outcome = _post(url, events[event_index]);
        posts_left -= 1;
        if outcome == RETRY {
            stalled = True;
            break;
        }
        event_index += 1;
        if outcome == ACCEPTED {
            accepted += 1;
        } else {
            rejected += 1;
        }
    }
    return (accepted, rejected, posts_left, events[event_index:] if stalled else None);
}

def _sending_files -> list[Path] {
    spool = _spool_path();
    return []
        if not spool.parent.is_dir()
        else sorted(spool.parent.glob(f"{spool.name}.*.sending"));
}

def _rotate_spool -> list[Path] {
    spool = _spool_path();
    files: list[Path] = [];
    with contextlib.suppress(OSError) {
        if spool.is_file() and spool.stat().st_size {
            target = spool.parent / f"{spool.name}.{uuid.uuid4().hex}.sending";
            os.replace(spool, target);
            files.append(target);
        }
    }
    return files;
}

def _promote_drop_counter {
    counter = _drop_counter();
    try {
        dropped = int(counter.read_text(encoding="utf-8").strip()) if counter.is_file() else 0;
    } except (OSError, ValueError) {
        dropped = 0;
    }
    if dropped <= 0 {
        return;
    }
    try {
        counter.unlink(missing_ok=True);
    } except OSError {
        return;
    }
    record(CLI_EVENTS_DROPPED, properties={"dropped_count": dropped});
}

def _read(path: Path) -> list[dict[str, Any]] {
    events: list[dict[str, Any]] = [];
    try {
        raw = path.read_text(encoding="utf-8");
    } except OSError {
        return events;
    }
    for line in raw.splitlines() {
        if not line.strip() {
            continue;
        }
        try {
            event = json.loads(line);
        } except ValueError {
            continue;
        }
        if isinstance(event, dict) {
            events.append(event);
        }
    }
    return events;
}

def _unlink(path: Path) {
    with contextlib.suppress(OSError) {
        path.unlink(missing_ok=True);
    }
}

def _retain(path: Path, events: list[dict[str, Any]]) {
    lines = "".join(
        (json.dumps(event, ensure_ascii=False, default=str) + "\n" for event in events)
    );
    temp = path.parent / f"{path.name}.partial";
    try {
        temp.write_text(lines, encoding="utf-8");
        os.replace(temp, path);
    } except OSError {
        _unlink(temp);
    }
}

def _headers -> dict[str, str] {
    headers = {"Content-Type": "application/json", "User-Agent": f"memu-cli/{client_version()}"};
    key = env("MEMU_CLOUD_API_KEY");
    if key {
        headers["Authorization"] = f"Bearer {key}";
    }
    return headers;
}

glob RETRY: any,
     REJECTED: any,
     ACCEPTED: any;

with entry {
    (ACCEPTED, REJECTED, RETRY) = ("accepted", "rejected", "retry");
}

def _debug(message: str) {
    if os.environ.get("MEMU_EVENTS_DEBUG") == "1" {
        print(f"[memu.events] {message}", file=sys.stderr);
    }
}

def _failure_name(exc: BaseException) -> str {
    reason = getattr(exc, "reason", None);
    return type(reason if isinstance(reason, BaseException) else exc).__name__;
}

def _post(url: str, event: dict[str, Any]) -> str {
    body = json.dumps(event, ensure_ascii=False, default=str).encode("utf-8");
    request = urllib.request.Request(url, data=body, headers=_headers(), method="POST");
    try {
        with urllib.request.urlopen(
            request, timeout=_TIMEOUT_SECONDS, **trust.urlopen_kwargs()
        ) as response {
            status = getattr(response, "status", 200);
            if 200 <= status < 300 {
                _debug(f"delivery accepted: HTTP {status}");
                return ACCEPTED;
            }
            _debug(f"delivery failed: HTTP {status}; spool retained for retry");
            return RETRY;
        }
    } except urllib.error.HTTPError as exc {
        if exc.code >= 400 and exc.code < 500 and exc.code != 429 {
            _debug(f"delivery rejected: HTTP {exc.code}; event discarded");
            return REJECTED;
        }
        _debug(f"delivery failed: HTTP {exc.code}; spool retained for retry");
        return RETRY;
    } except Exception as exc {
        _debug(f"delivery failed: {_failure_name(exc)}; spool retained for retry");
        return RETRY;
    }
}

def counts(
    result: dict[str, Any], layers: Iterable[str] = ("segments", "files", "resources")
) -> int {
    return sum((len(result.get(layer, []) or []) for layer in layers));
}
