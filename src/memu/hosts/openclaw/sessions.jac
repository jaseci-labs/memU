import datetime;
import json;
import logging;
import os;
import re;
import sqlite3;
import from pathlib { Path }
import from typing { ClassVar, Optional }
glob logger = logging.getLogger(__name__),
     SESSION_DIR = "~/.openclaw/agents",
     _MESSAGE_ROLES = ("user", "assistant"),
     _RECORD_PRIVATE_FIELDS = frozenset({"id", "parentId", "timestamp"}),
     _MESSAGE_PRIVATE_FIELDS = frozenset({
         "__openclaw",
         "api",
         "errorBody",
         "errorCode",
         "errorMessage",
         "errorType",
         "idempotencyKey",
         "model",
         "openclawDeliveryMirror",
         "provider",
         "responseId",
         "stopReason",
         "timestamp",
         "usage",
     }),
     _TOOL_RESULT_PRIVATE_FIELDS = frozenset({"details"}),
     _BLOCK_PRIVATE_FIELDS = frozenset({"partialArgs", "textSignature", "thinkingSignature"}),
     _SIDECAR_MARKERS = (".trajectory.", ".checkpoint."),
     _STORE_SUBDIR = "agent",
     _STORE_NAME = "openclaw-agent.sqlite",
     _IMPORT_ARCHIVE_DIR = "session-sqlite-import-archive",
     _SESSION_SUFFIX = ".jsonl";

class OpenClawTranscriptSource(TranscriptSource) {
    has _stored_paths: set[Path],
        _root: any;
    static has name: ClassVar[str] = "openclaw";

    def init(session_dir: str | Path = SESSION_DIR) {
        self._root = Path(os.path.expanduser(str(session_dir)));
        self._stored_paths = set();
    }

    def `root -> Path {
        return self._root;
    }

    def _databases -> list[Path] {
        if not self._root.is_dir() {
            return [];
        }
        return sorted(
            (path for path in self._root.glob(f"*/{_STORE_SUBDIR}/{_STORE_NAME}") if path.is_file())
        );
    }

    def _connect(db: Path) -> sqlite3.Connection {
        return sqlite3.connect(f"{db.resolve().as_uri()}?mode=ro", uri=True);
    }

    def _query(db: Path, sql: str, *args: object) -> list[tuple[any, ...]] {
        try {
            conn = self._connect(db);
        } except sqlite3.Error as exc {
            raise TranscriptReadError(db, exc) from exc;
        }
        try {
            return conn.execute(sql, args).fetchall();
        } except sqlite3.Error as exc {
            raise TranscriptReadError(db, exc) from exc;
        } finally {
            conn.close();
        }
    }

    def supports_cron_run_identity -> bool {
        for db in self._databases() {
            if not db.is_file() {
                continue;
            }
            try {
                columns = self._query(db, "PRAGMA table_info(session_windows)");
            } except TranscriptReadError {
                continue;
            }
            names: set[str] = {
                row[1]
                for row in columns
                if len(row) > 1 and isinstance(row[1], str)
            };
            if {"session_id", "session_key"} <= names {
                return True;
            }
        }
        return False;
    }

    def session_id(path: Path) -> str {
        store_id = path.relative_to(self._root).parts[0];
        return f"{store_id}/{path.stem}";
    }

    def cron_run_session_ids(*, job_id: str) -> list[str] {
        session_ids: list[str] = [];
        job_key = re.escape(job_id);
        for db in self._databases() {
            try {
                columns = self._query(db, "PRAGMA table_info(session_windows)");
            } except TranscriptReadError {
                continue;
            }
            names: set[str] = {
                row[1]
                for row in columns
                if len(row) > 1 and isinstance(row[1], str)
            };
            if not {"session_id", "session_key"} <= names {
                continue;
            }
            try {
                rows = self._query(
                    db,
                    "SELECT session_id, session_key FROM session_windows WHERE session_key GLOB 'agent:*:cron:' || ? || ':run:*' ORDER BY session_id",
                    job_id,
                );
            } except TranscriptReadError as exc {
                logger.warning(
                    "could not resolve OpenClaw cron sessions from %s: %s", db, exc.cause
                );
                continue;
            }
            store_id = db.parent.parent.name;
            session_ids.extend([
                f"{store_id}/{session_id}"
                for (session_id, session_key) in rows
                if isinstance(session_id, str)
                    and session_id
                    and isinstance(session_key, str)
                    and re.fullmatch(
                        f"agent:[^:]+:cron:{job_key}:run:{re.escape(session_id)}", session_key
                    )
            ]);
        }
        return list(dict.fromkeys(session_ids));
    }

    def _virtual_path(db: Path, session_id: str) -> Path {
        return db.parent.parent / "sessions" / f"{session_id}{_SESSION_SUFFIX}";
    }

    def _stored_session(path: Path) -> Optional[tuple[Path, str]] {
        if path not in self._stored_paths {
            return None;
        }
        try {
            parts = path.relative_to(self._root).parts;
        } except ValueError {
            return None;
        }
        if len(parts) != 3 or parts[1] != "sessions" or (not parts[2].endswith(_SESSION_SUFFIX)) {
            return None;
        }
        db = self._root / parts[0] / _STORE_SUBDIR / _STORE_NAME;
        return (db, parts[2][:-len(_SESSION_SUFFIX)]) if db.is_file() else None;
    }

    def discover -> list[Path] {
        stored: list[tuple[float, Path]] = [];
        for db in self._databases() {
            try {
                rows = self._query(
                    db,
                    "SELECT w.session_id, COALESCE(w.transcript_updated_at, MAX(e.created_at)) FROM transcript_events AS e JOIN session_windows AS w ON w.session_id = e.session_id GROUP BY w.session_id, w.transcript_updated_at",
                );
            } except TranscriptReadError as exc {
                logger.warning(
                    "skipping unreadable OpenClaw transcript store %s: %s", db, exc.cause
                );
                continue;
            }
            stored.extend([
                (last_at / 1000, self._virtual_path(db, session_id))
                for (session_id, last_at) in rows
            ]);
        }
        claimed = {path for (_, path) in stored};
        self._stored_paths = claimed;
        files: list[tuple[float, any]] = [
            (path.stat().st_mtime, path)
            for path in super.discover()
            if not any([marker in path.name for marker in _SIDECAR_MARKERS])
                and _IMPORT_ARCHIVE_DIR not in path.parts
                and (path not in claimed)
        ];
        merged = stored + files;
        merged.sort(key=lambda (`entry: any) -> any { `entry[0] }, reverse=True);
        return [path for (_, path) in merged];
    }

    def read_records(path: Path) -> list[str] {
        stored = self._stored_session(path);
        if stored is not None {
            (db, session_id) = stored;
            rows = self._query(
                db,
                "SELECT event_json FROM transcript_events WHERE session_id = ? ORDER BY seq",
                session_id,
            );
            return [event_json for (event_json,) in rows];
        }
        return super.read_records(path);
    }

    def read_incremental(path: Path, previous: Optional[dict[str, object]]) -> TranscriptRead {
        stored = self._stored_session(path);
        if stored is None {
            return super.read_incremental(path, previous);
        }
        (db, session_id) = stored;
        rows = self._query(
            db,
            "SELECT r.generation, e.event_json FROM transcript_rewrite_watermarks AS r LEFT JOIN transcript_events AS e ON e.session_id = r.session_id WHERE r.session_id = ? ORDER BY e.seq",
            session_id,
        );
        if not rows {
            error = sqlite3.DatabaseError(
                f"missing transcript generation for session {session_id}"
            );
            raise TranscriptReadError(db, error) from error;
        }
        generation = rows[0][0];
        records = [event_json for (_, event_json) in rows if event_json is not None];
        previous_lines = previous.get("lines", 0) if previous else 0;
        if not isinstance(previous_lines, int) {
            previous_lines = 0;
        }
        previous_generation = previous.get("generation") if previous else None;
        previous_container = previous.get("container") if previous else None;
        same_generation = previous_container == "sqlite" and previous_generation == generation;
        start = previous_lines if same_generation else 0;
        return TranscriptRead(
            records=records,
            start=start,
            cursor={"container": "sqlite", "generation": generation, "lines": len(records)},
        );
    }

    def sanitize(path: Path, record: str) -> str {
        del path;
        return sanitize_agent_record(
            record,
            record_fields=_RECORD_PRIVATE_FIELDS,
            message_fields=_MESSAGE_PRIVATE_FIELDS,
            tool_result_fields=_TOOL_RESULT_PRIVATE_FIELDS,
            block_fields=_BLOCK_PRIVATE_FIELDS,
        );
    }

    def classify(record: str) -> RecordKind {
        try {
            `entry = json.loads(record);
        } except json.JSONDecodeError {
            return RecordKind.OTHER;
        }
        if not isinstance(`entry, dict) or `entry.get("type") != "message" {
            return RecordKind.OTHER;
        }
        message = `entry.get("message");
        role = message.get("role") if isinstance(message, dict) else None;
        if role in _MESSAGE_ROLES {
            return RecordKind.MESSAGE;
        }
        return RecordKind.TOOL if role == "toolResult" else RecordKind.OTHER;
    }

    def timestamp(record: str) -> str | None {
        try {
            value = json.loads(record).get("timestamp");
        } except (json.JSONDecodeError, AttributeError) {
            return None;
        }
        if isinstance(value, str) {
            return value;
        }
        if isinstance(value, (int, float)) {
            seconds = value / 1000 if value > 100000000000.0 else value;
            return datetime.datetime.fromtimestamp(seconds, tz=datetime.UTC).isoformat();
        }
        return None;
    }
}
