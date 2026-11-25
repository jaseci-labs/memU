impl CursorTranscriptSource.init(session_dir: str | Path = SESSION_DIR) {
    self._root = Path(os.path.expanduser(str(session_dir)));
}

impl CursorTranscriptSource.`root -> Path {
    return self._root;
}

impl CursorTranscriptSource.discover -> list[Path] {
    `root = self.root();
    if not `root.is_dir() {
        return [];
    }
    files = [path for path in `root.glob("*/agent-transcripts/**/*.jsonl") if path.is_file()];
    files.sort(key=lambda (path: any) -> any { path.stat().st_mtime }, reverse=True);
    return files;
}

impl CursorTranscriptSource.classify(record: str) -> RecordKind {
    try {
        `entry = json.loads(record);
    } except json.JSONDecodeError {
        return RecordKind.OTHER;
    }
    if not isinstance(`entry, dict) or `entry.get("role") not in ("user", "assistant") {
        return RecordKind.OTHER;
    }
    message = `entry.get("message");
    content = message.get("content") if isinstance(message, dict) else None;
    if isinstance(content, str) {
        return RecordKind.MESSAGE;
    }
    if not isinstance(content, list) {
        return RecordKind.OTHER;
    }
    kinds: any = {block.get("type") for block in content if isinstance(block, dict)};
    if "text" in kinds {
        return RecordKind.MESSAGE;
    }
    if kinds & {"tool_use", "tool_result"} {
        return RecordKind.TOOL;
    }
    return RecordKind.OTHER;
}
