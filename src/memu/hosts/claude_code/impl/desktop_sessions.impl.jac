impl ClaudeDesktopTranscriptSource.init(
    session_dir: str | Path, cowork_roots: Optional[list[str | Path]] = None
) {
    self._code = ClaudeCodeTranscriptSource(session_dir);
    self._cowork = CoworkTranscriptSource(cowork_roots);
}

impl ClaudeDesktopTranscriptSource.`root -> Path {
    return self._code.root();
}

impl ClaudeDesktopTranscriptSource.exists -> bool {
    return self._code.exists() or self._cowork.exists();
}

impl ClaudeDesktopTranscriptSource._source(path: Path) -> TranscriptSource {
    return self._cowork
        if any([path.is_relative_to(`root) for `root in self._cowork.roots])
        else self._code;
}

impl ClaudeDesktopTranscriptSource.discover -> list[Path] {
    paths = [*self._code.discover(), *self._cowork.discover()];
    paths.sort(key=lambda (path: any) -> any { path.stat().st_mtime }, reverse=True);
    return paths;
}

impl ClaudeDesktopTranscriptSource.read_records(path: Path) -> list[str] {
    return self._source(path).read_records(path);
}

impl ClaudeDesktopTranscriptSource.read_incremental(
    path: Path, previous: Optional[dict[str, object]]
) -> TranscriptRead {
    return self._source(path).read_incremental(path, previous);
}

impl ClaudeDesktopTranscriptSource.classify(record: str) -> RecordKind {
    return self._code.classify(record);
}

impl ClaudeDesktopTranscriptSource.sanitize(path: Path, record: str) -> str {
    return self._source(path).sanitize(path, record);
}

impl ClaudeDesktopTranscriptSource.timestamp(record: str) -> str | None {
    return self._code.timestamp(record);
}

impl ClaudeDesktopTranscriptSource.key(path: Path) -> str {
    return self._source(path).key(path);
}

impl ClaudeDesktopTranscriptSource.scan_region(path: Path) -> str {
    if self._source(path) is self._cowork {
        `root = next((`root for `root in self._cowork.roots if path.is_relative_to(`root)));
        return f"cowork:{`root}";
    }
    return "claude-code";
}

impl ClaudeDesktopTranscriptSource.session_id(path: Path) -> str {
    return self._source(path).session_id(path);
}
