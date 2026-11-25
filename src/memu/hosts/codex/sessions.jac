import json;
import os;
import from pathlib { Path }
import from typing { ClassVar }
import from uuid { UUID }
glob SESSION_DIR = "~/.codex/sessions",
     _MESSAGE_ROLES = ("user", "assistant"),
     _TOOL_TYPES = ("function_call", "function_call_output"),
     _RECORD_PRIVATE_FIELDS = frozenset({"timestamp"}),
     _PAYLOAD_PRIVATE_FIELDS = frozenset({"id", "internal_chat_message_metadata_passthrough"}),
     _INJECTED_PREFIXES = (
         "<environment_context>",
         "<turn_aborted>",
         "# AGENTS.md instructions for",
     );

def _injected(payload: dict[any, any]) -> bool {
    if payload.get("role") != "user" {
        return False;
    }
    content = payload.get("content");
    if not isinstance(content, list) {
        return False;
    }
    texts = [item.get("text", "") for item in content if isinstance(item, dict)];
    return bool(texts) and all((text.lstrip().startswith(_INJECTED_PREFIXES) for text in texts));
}

class CodexTranscriptSource(TranscriptSource) {
    has _root: any;
    static has name: ClassVar[str] = "codex";

    def init(session_dir: str | Path = SESSION_DIR) {
        self._root = Path(os.path.expanduser(str(session_dir)));
    }

    def `root -> Path {
        return self._root;
    }

    def session_id(path: Path) -> str {
        try {
            return str(UUID(path.stem[-36:]));
        } except ValueError {
            return path.stem;
        }
    }

    def sanitize(path: Path, record: str) -> str {
        del path;
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
        payload = `entry.get("payload");
        if isinstance(payload, dict) {
            for field in _PAYLOAD_PRIVATE_FIELDS {
                if field in payload {
                    del payload[field];
                    changed = True;
                }
            }
        }
        return json.dumps(`entry, ensure_ascii=False) if changed else record;
    }

    def classify(record: str) -> RecordKind {
        try {
            payload = json.loads(record).get("payload");
        } except (json.JSONDecodeError, AttributeError) {
            return RecordKind.OTHER;
        }
        if not isinstance(payload, dict) {
            return RecordKind.OTHER;
        }
        kind = payload.get("type");
        if kind == "message" and payload.get("role") in _MESSAGE_ROLES {
            return RecordKind.OTHER if _injected(payload) else RecordKind.MESSAGE;
        }
        return RecordKind.TOOL if kind in _TOOL_TYPES else RecordKind.OTHER;
    }
}
