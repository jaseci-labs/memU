impl ClaudeCodeTranscriptSource.init(session_dir: str | Path = SESSION_DIR) {
    self._root = Path(os.path.expanduser(str(session_dir)));
}

impl ClaudeCodeTranscriptSource.`root -> Path {
    return self._root;
}

impl ClaudeCodeTranscriptSource.session_id(path: Path) -> str {
    parts = path.relative_to(self.root()).parts;
    return parts[1] if len(parts) > 2 else path.stem;
}

impl ClaudeCodeTranscriptSource.classify(record: str) -> RecordKind {
    return classify_claude_record(record);
}

impl ClaudeCodeTranscriptSource.sanitize(path: Path, record: str) -> str {
    try {
        `entry = json.loads(record);
    } except json.JSONDecodeError {
        return record;
    }
    if not isinstance(`entry, dict) {
        return record;
    }
    changed = False;
    for field in _RECORD_PRIVATE_FIELDS {
        if field in `entry {
            del `entry[field];
            changed = True;
        }
    }
    message = `entry.get("message");
    if isinstance(message, dict) {
        for field in _MESSAGE_PRIVATE_FIELDS {
            if field in message {
                del message[field];
                changed = True;
            }
        }
    }
    return json.dumps(`entry, ensure_ascii=False) if changed else record;
}
