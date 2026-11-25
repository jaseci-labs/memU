impl TranscriptReadError.init(path: Path, cause: BaseException) {
    self.path = path;
    self.cause = cause;
    super.init(f"could not read transcript data from {path}: {cause}");
}

impl TranscriptSource.sanitize(path: Path, record: str) -> str {
    return record;
}

impl TranscriptSource.exists -> bool {
    return self.root().is_dir();
}

impl TranscriptSource.discover -> list[Path] {
    `root = self.root();
    if not `root.is_dir() {
        return [];
    }
    files = [path for path in `root.rglob("*.jsonl") if path.is_file()];
    files.sort(key=lambda (path: any) -> any { path.stat().st_mtime }, reverse=True);
    return files;
}

impl TranscriptSource.read_records(path: Path) -> list[str] {
    with path.open(encoding="utf-8") as handle {
        return [line for line in (raw.strip() for raw in handle) if line];
    }
}

impl TranscriptSource.read_incremental(
    path: Path, previous: dict[str, object] | None
) -> TranscriptRead {
    records = self.read_records(path);
    start = previous.get("lines", 0) if previous else 0;
    if not isinstance(start, int) {
        start = 0;
    }
    return TranscriptRead(records=records, start=start, cursor={"lines": len(records)});
}

impl TranscriptSource.timestamp(record: str) -> str | None {
    try {
        value = json.loads(record).get("timestamp");
    } except (json.JSONDecodeError, AttributeError) {
        return None;
    }
    return value if isinstance(value, str) else None;
}

impl TranscriptSource.key(path: Path) -> str {
    return path.relative_to(self.root()).as_posix();
}

impl TranscriptSource.scan_region(path: Path) -> str {
    return "default";
}

impl TranscriptSource.session_id(path: Path) -> str {
    return path.stem;
}
