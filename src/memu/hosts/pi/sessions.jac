import json;
import from pathlib { Path }
import from typing { ClassVar }
glob AGENT_DIR = "~/.pi/agent",
     SESSION_DIR = "~/.pi/agent/sessions",
     _RECORD_PRIVATE_FIELDS = frozenset({"id", "parentId", "timestamp"}),
     _MESSAGE_PRIVATE_FIELDS = frozenset({
         "api",
         "errorMessage",
         "model",
         "provider",
         "rawStopReason",
         "responseId",
         "stopReason",
         "timestamp",
         "usage",
     }),
     _TOOL_RESULT_PRIVATE_FIELDS = frozenset({"details"}),
     _BLOCK_PRIVATE_FIELDS = frozenset({"thinkingSignature"});

class PiTranscriptSource(TranscriptSource) {
    has _root: any;
    static has name: ClassVar[str] = "pi";

    def init(session_dir: str | Path = SESSION_DIR) {
        self._root = Path(session_dir).expanduser();
    }

    def `root -> Path {
        return self._root;
    }

    def session_id(path: Path) -> str {
        return path.stem.rsplit("_", 1)[-1];
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
}
