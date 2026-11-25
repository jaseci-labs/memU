impl PiTranscriptSource.init(session_dir: str | Path = SESSION_DIR) {
    self._root = Path(session_dir).expanduser();
}

impl PiTranscriptSource.`root -> Path {
    return self._root;
}

impl PiTranscriptSource.session_id(path: Path) -> str {
    return path.stem.rsplit("_", 1)[-1];
}

impl PiTranscriptSource.sanitize(path: Path, record: str) -> str {
    del path;
    return sanitize_agent_record(
        record,
        record_fields=_RECORD_PRIVATE_FIELDS,
        message_fields=_MESSAGE_PRIVATE_FIELDS,
        tool_result_fields=_TOOL_RESULT_PRIVATE_FIELDS,
        block_fields=_BLOCK_PRIVATE_FIELDS,
    );
}

impl PiTranscriptSource.classify(record: str) -> RecordKind {
    try {
        `entry = json.loads(record);
    } except json.JSONDecodeError {
        return RecordKind.OTHER;
    }
    if not isinstance(`entry, dict) or `entry.get("type") != "message" {
        return RecordKind.OTHER;
    }
    message = `entry.get("message");
    if not isinstance(message, dict) {
        return RecordKind.OTHER;
    }
    role = message.get("role");
    if role in {"toolResult", "bashExecution"} {
        return RecordKind.TOOL;
    }
    if role not in {"user", "assistant"} {
        return RecordKind.OTHER;
    }
    content = message.get("content");
    if isinstance(content, str) {
        return RecordKind.MESSAGE;
    }
    if not isinstance(content, list) {
        return RecordKind.OTHER;
    }
    block_types: any = {block.get("type") for block in content if isinstance(block, dict)};
    if "text" in block_types {
        return RecordKind.MESSAGE;
    }
    if "toolCall" in block_types {
        return RecordKind.TOOL;
    }
    return RecordKind.OTHER;
}
