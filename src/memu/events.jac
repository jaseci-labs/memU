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
import from typing { Any }
glob DEFAULT_EVENTS_URL = "https://api.memu.so/api/memu/analytics/events";

with entry {}

glob MEMORY_SEARCH_SUCCEEDED = "memory_search_succeeded",
     MEMORY_SEARCH_FAILED = "memory_search_failed";

with entry {}

glob MEMORY_LIST_SUCCEEDED = "memory_list_succeeded",
     MEMORY_LIST_FAILED = "memory_list_failed";

with entry {}

glob MEMORY_COMMIT_SUCCEEDED = "memory_commit_succeeded",
     MEMORY_COMMIT_FAILED = "memory_commit_failed";

with entry {}

glob MEMORY_UPDATE_STARTED = "memory_update_started",
     MEMORY_UPDATE_SUCCEEDED = "memory_update_succeeded",
     MEMORY_UPDATE_FAILED = "memory_update_failed";

with entry {}

glob CLI_INSTALL_STARTED = "cli_install_started";

with entry {}

glob INSTALL_GUIDE_OPENED = "install_guide_opened";

with entry {}

glob CLI_INSTALL_SUCCEEDED = "cli_install_succeeded";

with entry {}

glob CLI_INSTALL_FAILED = "cli_install_failed",
     UNINSTALL_GUIDE_OPENED = "uninstall_guide_opened";

with entry {}

glob CLI_UNINSTALL_SUCCEEDED = "cli_uninstall_succeeded",
     CLI_UNINSTALL_FAILED = "cli_uninstall_failed";

with entry {}

glob AGENT_ERROR_REPORTED = "agent_error_reported";

with entry {}

glob CLI_ERROR = "cli_error";

with entry {}

glob CLI_EVENTS_DROPPED = "cli_events_dropped";

with entry {}

glob CLIENT_TYPE = "memu_cli",
     SPOOL_PATH = "~/.memu/events.jsonl";

with entry {}

glob MAX_SPOOL_BYTES = 1024 * 1024;

with entry {}

glob MAX_FLUSH_POSTS = 200;

with entry {}

glob MAX_DETAIL_CHARS = 5000;

with entry {}

glob MAX_FRAMES = 20;

with entry {}

glob ERROR_DEDUP_SECONDS = 3600.0;

with entry {}

glob MAX_LEDGER_ENTRIES = 200;

with entry {}

glob _TIMEOUT_SECONDS = 5.0,
     STAGES: tuple[str, ...] = ("install", "uninstall", "remember", "retrieve", "other");

with entry {}

glob _READ_COUNTS = frozenset({"result_count", "latency_ms"});

with entry {}

glob _WRITE_COUNTS = frozenset({"recall_file_count", "resource_count", "session_count"});

with entry {}

glob _ALLOWED_PROPERTIES: dict[str, frozenset[str]] = {
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
};

with entry {}

glob REPORTED_BY_CODE = "code",
     REPORTED_BY_AGENT = "agent",
     _AGENT_REPORTED: frozenset[str] = frozenset({
         CLI_INSTALL_SUCCEEDED,
         CLI_INSTALL_FAILED,
         CLI_UNINSTALL_SUCCEEDED,
         CLI_UNINSTALL_FAILED,
         MEMORY_UPDATE_FAILED,
         AGENT_ERROR_REPORTED,
     });

with entry {}

glob STAGE_FAILURE_EVENTS: dict[str, str] = {
    "install": CLI_INSTALL_FAILED,
    "uninstall": CLI_UNINSTALL_FAILED,
    "remember": MEMORY_UPDATE_FAILED,
};

with entry {}

glob AGENT_PLATFORMS: dict[str, str] = {"claude-code": "claude_code"};

with entry {}

def _off(value: str | None) -> bool;
def _on(value: str | None) -> bool;
def events_url -> str | None;
def enabled -> bool;
def _spool_path -> Path;
def client_version -> str;
def client_instance_id -> str;
def reported_by(event_name: str) -> str;
def agent_platform(host: str | None) -> str;
def _os_name -> str;
def _now -> str;
def _session_id(session_id_env: str) -> str;
def envelope(
    event_name: str,
    *,
    host: str = "",
    session_id_env: str = "",
    properties: dict[str, Any] | None = None,
) -> dict[str, Any];
def record(
    event_name: str,
    *,
    host: str = "",
    session_id_env: str = "",
    properties: dict[str, Any] | None = None,
    deliver: bool = False,
);
def _deliver(event: dict[str, Any]) -> bool;
def _filter(event_name: str, properties: dict[str, Any] | None) -> dict[str, Any];
def _append(line: str);
def _drop_counter -> Path;
def _count_drop;
def record_outcome(
    succeeded: str,
    failed: str,
    *,
    host: str = "",
    session_id_env: str = "",
    success: bool,
    deliver: bool = False,
    **counts: Any,
);
def record_list(
    *, started: float, listed: int, success: bool, host: str = "", session_id_env: str = ""
);
def record_agent_error(*, stage: str, detail: str = "", host: str = "", session_id_env: str = "");
def _error_ledger -> Path;
def _claim_error(stage: str, detail: str) -> bool;
def _stamp(`entry: dict[str, Any]) -> float;
def record_cli_error(
    exc: BaseException, *, command: str = "", host: str = "", session_id_env: str = ""
);
def _frames(exc: BaseException) -> list[str];
def _module_of(filename: str) -> str;
def flush -> tuple[int, int];
def _flush -> tuple[int, int];
def _drain(path: Path, url: str, posts_left: int) -> tuple[int, int, int, list[dict[str, Any]]
    | None];
def _sending_files -> list[Path];
def _rotate_spool -> list[Path];
def _promote_drop_counter;
def _read(path: Path) -> list[dict[str, Any]];
def _unlink(path: Path);
def _retain(path: Path, events: list[dict[str, Any]]);
def _headers -> dict[str, str];
glob RETRY: any,
     REJECTED: any,
     ACCEPTED: any;

with entry {
    (ACCEPTED, REJECTED, RETRY) = ("accepted", "rejected", "retry");
}

def _debug(message: str);
def _failure_name(exc: BaseException) -> str;
def _post(url: str, event: dict[str, Any]) -> str;
def counts(
    result: dict[str, Any], layers: Iterable[str] = ("segments", "files", "resources")
) -> int;
