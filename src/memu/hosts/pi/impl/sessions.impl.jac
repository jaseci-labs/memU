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
