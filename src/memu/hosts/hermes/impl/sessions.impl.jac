impl hermes_home -> Path {
    if (value := os.environ.get("HERMES_HOME", "").strip()) {
        return Path(os.path.expandvars(value)).expanduser();
    }
    suffix = os.environ.get("HERMES_DATA_DIR_SUFFIX", "");
    if sys.platform == "win32" {
        local_appdata = os.environ.get("LOCALAPPDATA", "").strip();
        `root = Path(local_appdata) if local_appdata else Path.home() / "AppData" / "Local";
        return `root / ("hermes" + suffix);
    }
    return Path.home() / (".hermes" + suffix);
}

impl state_db_path -> Path {
    return hermes_home() / "state.db";
}

impl HermesTranscriptSource.init(state_db: str | Path | None = None) {
    self._db = Path(os.path.expanduser(str(state_db))) if state_db is not None else state_db_path();
}

impl HermesTranscriptSource.`root -> Path {
    return self._db.parent;
}

impl HermesTranscriptSource.exists -> bool {
    return self._db.is_file();
}

impl HermesTranscriptSource.key(path: Path) -> str {
    return path.name;
}

impl HermesTranscriptSource.session_id(path: Path) -> str {
    return path.name;
}

impl HermesTranscriptSource._connect -> sqlite3.Connection {
    return sqlite3.connect(f"{self._db.resolve().as_uri()}?mode=ro", uri=True);
}

impl HermesTranscriptSource.discover -> list[Path] {
    if not self.exists() {
        return [];
    }
    with self._connect() as conn {
        rows = conn.execute(
            "SELECT session_id FROM messages GROUP BY session_id ORDER BY MAX(timestamp) DESC"
        ).fetchall();
    }
    return [self.root() / session_id for (session_id,) in rows];
}

impl HermesTranscriptSource.read_records(path: Path) -> list[str] {
    with self._connect() as conn {
        rows = conn.execute(
            f"SELECT {', '.join(_ROW_COLUMNS)} FROM messages WHERE session_id = ? ORDER BY id",
            (path.name,),
        ).fetchall();
    }
    return [
        json.dumps(
            {
                column: value
                for (column, value) in builtins.zip(_ROW_COLUMNS, row, strict=True)
                if value is not None
            },
            ensure_ascii=False,
        )
        for row in rows
    ];
}

impl HermesTranscriptSource.classify(record: str) -> RecordKind {
    try {
        row = json.loads(record);
    } except json.JSONDecodeError {
        return RecordKind.OTHER;
    }
    if not isinstance(row, dict) {
        return RecordKind.OTHER;
    }
    role = row.get("role");
    if role == "tool" {
        return RecordKind.TOOL;
    }
    if role in _MESSAGE_ROLES {
        content = row.get("content");
        if role == "user" and isinstance(content, str) {
            content = DELIVERY_PATTERN.sub("", content).strip();
        }
        if content {
            return RecordKind.MESSAGE;
        }
        if row.get("tool_calls") {
            return RecordKind.TOOL;
        }
    }
    return RecordKind.OTHER;
}

impl HermesTranscriptSource.sanitize(path: Path, record: str) -> str {
    row = json.loads(record);
    content = row.get("content");
    if row.get("role") == "user" and isinstance(content, str) and DELIVERY_PATTERN.search(content) {
        row["content"] = DELIVERY_PATTERN.sub("", content).strip();
        return json.dumps(row, ensure_ascii=False);
    }
    return record;
}

impl HermesTranscriptSource.timestamp(record: str) -> str | None {
    try {
        value = json.loads(record).get("timestamp");
    } except (json.JSONDecodeError, AttributeError) {
        return None;
    }
    if isinstance(value, (int, float)) {
        return datetime.datetime.fromtimestamp(value, tz=datetime.UTC).isoformat();
    }
    return value if isinstance(value, str) else None;
}
