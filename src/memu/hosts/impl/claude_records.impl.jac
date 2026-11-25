impl classify_claude_record(record: str) -> RecordKind {
    try {
        `entry = json.loads(record);
    } except json.JSONDecodeError {
        return RecordKind.OTHER;
    }
    if not isinstance(`entry, dict) or `entry.get("type") not in ("user", "assistant") {
        return RecordKind.OTHER;
    }
    message = `entry.get("message");
    if not isinstance(message, dict) {
        return RecordKind.OTHER;
    }
    content = message.get("content");
    if isinstance(content, str) {
        return RecordKind.OTHER if `entry.get("isMeta") else RecordKind.MESSAGE;
    }
    kinds: any = {
        block["type"]
        for block in content
        if isinstance(block, dict) and isinstance(block.get("type"), str)
    }
        if isinstance(content, list)
        else set[str]();
    if "text" in kinds {
        return RecordKind.OTHER if `entry.get("isMeta") else RecordKind.MESSAGE;
    }
    if kinds & {"tool_use", "tool_result"} {
        return RecordKind.TOOL;
    }
    return RecordKind.OTHER;
}
