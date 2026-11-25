impl _drop_known_fields(value: dict[object, object], fields: frozenset[str]) -> bool {
    changed = False;
    for field in fields {
        if field in value {
            del value[field];
            changed = True;
        }
    }
    return changed;
}

impl OpenClawTranscriptSource.init(session_dir: str | Path = SESSION_DIR) {
    self._root = Path(os.path.expanduser(str(session_dir)));
    self._stored_paths = set();
}

impl OpenClawTranscriptSource.`root -> Path {
    return self._root;
}

impl OpenClawTranscriptSource._databases -> list[Path] {
    if not self._root.is_dir() {
        return [];
    }
    return sorted(
        (path for path in self._root.glob(f"*/{_STORE_SUBDIR}/{_STORE_NAME}") if path.is_file())
    );
}

impl OpenClawTranscriptSource._connect(db: Path) -> sqlite3.Connection {
    return sqlite3.connect(f"{db.resolve().as_uri()}?mode=ro", uri=True);
}

impl OpenClawTranscriptSource._query(db: Path, sql: str, *args: object) -> list[tuple[any, ...]] {
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

impl OpenClawTranscriptSource.supports_cron_run_identity -> bool {
    for db in self._databases() {
        if not db.is_file() {
            continue;
        }
        try {
            columns = self._query(db, "PRAGMA table_info(session_windows)");
        } except TranscriptReadError {
            continue;
        }
        names: set[str] = {row[1] for row in columns if len(row) > 1 and isinstance(row[1], str)};
        if {"session_id", "session_key"} <= names {
            return True;
        }
    }
    return False;
}

impl OpenClawTranscriptSource.session_id(path: Path) -> str {
    store_id = path.relative_to(self._root).parts[0];
    return f"{store_id}/{path.stem}";
}

impl OpenClawTranscriptSource.cron_run_session_ids(*, job_id: str) -> list[str] {
    session_ids: list[str] = [];
    job_key = re.escape(job_id);
    for db in self._databases() {
        try {
            columns = self._query(db, "PRAGMA table_info(session_windows)");
        } except TranscriptReadError {
            continue;
        }
        names: set[str] = {row[1] for row in columns if len(row) > 1 and isinstance(row[1], str)};
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
            logger.warning("could not resolve OpenClaw cron sessions from %s: %s", db, exc.cause);
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

impl OpenClawTranscriptSource._virtual_path(db: Path, session_id: str) -> Path {
    return db.parent.parent / "sessions" / f"{session_id}{_SESSION_SUFFIX}";
}

impl OpenClawTranscriptSource._stored_session(path: Path) -> Optional[tuple[Path, str]] {
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

impl OpenClawTranscriptSource.discover -> list[Path] {
    stored: list[tuple[float, Path]] = [];
    for db in self._databases() {
        try {
            rows = self._query(
                db,
                "SELECT w.session_id, COALESCE(w.transcript_updated_at, MAX(e.created_at)) FROM transcript_events AS e JOIN session_windows AS w ON w.session_id = e.session_id GROUP BY w.session_id, w.transcript_updated_at",
            );
        } except TranscriptReadError as exc {
            logger.warning("skipping unreadable OpenClaw transcript store %s: %s", db, exc.cause);
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
        if not any((marker in path.name for marker in _SIDECAR_MARKERS))
            and _IMPORT_ARCHIVE_DIR not in path.parts
            and (path not in claimed)
    ];
    merged = stored + files;
    merged.sort(key=lambda (`entry: any) -> any { `entry[0] }, reverse=True);
    return [path for (_, path) in merged];
}

impl OpenClawTranscriptSource.read_records(path: Path) -> list[str] {
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

impl OpenClawTranscriptSource.read_incremental(
    path: Path, previous: Optional[dict[str, object]]
) -> TranscriptRead {
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
        error = sqlite3.DatabaseError(f"missing transcript generation for session {session_id}");
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

impl OpenClawTranscriptSource.sanitize(path: Path, record: str) -> str {
    del path;
    try {
        `entry = json.loads(record);
    } except json.JSONDecodeError {
        return record;
    }
    if not isinstance(`entry, dict) {
        return record;
    }
    changed = _drop_known_fields(`entry, _RECORD_PRIVATE_FIELDS);
    message = `entry.get("message");
    if not isinstance(message, dict) {
        return json.dumps(`entry, ensure_ascii=False) if changed else record;
    }
    changed |= _drop_known_fields(message, _MESSAGE_PRIVATE_FIELDS);
    if message.get("role") == "toolResult" {
        changed |= _drop_known_fields(message, _TOOL_RESULT_PRIVATE_FIELDS);
    }
    content = message.get("content");
    if isinstance(content, list) {
        for block in content {
            if isinstance(block, dict) {
                changed |= _drop_known_fields(block, _BLOCK_PRIVATE_FIELDS);
            }
        }
    }
    return json.dumps(`entry, ensure_ascii=False) if changed else record;
}

impl OpenClawTranscriptSource.classify(record: str) -> RecordKind {
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
    if role == "toolResult" {
        return RecordKind.TOOL;
    }
    return RecordKind.OTHER;
}

impl OpenClawTranscriptSource.timestamp(record: str) -> str | None {
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
