import datetime;
import json;
import os;
import from pathlib { Path }
import from typing { ClassVar }
glob SESSION_DIR = "~/.workbuddy/projects",
     _MESSAGE_ROLES = ("user", "assistant"),
     _TOOL_TYPES = ("function_call", "function_call_result");

class WorkBuddyTranscriptSource(TranscriptSource) {
    has _root: any;
    static has name: ClassVar[str] = "workbuddy";

    def init(session_dir: str | Path = SESSION_DIR) {
        self._root = Path(os.path.expanduser(str(session_dir)));
    }

    def `root -> Path {
        return self._root;
    }

    def classify(record: str) -> RecordKind {
        try {
            `entry = json.loads(record);
        } except json.JSONDecodeError {
            return RecordKind.OTHER;
        }
        if not isinstance(`entry, dict) {
            return RecordKind.OTHER;
        }
        typ = `entry.get("type");
        if typ == "message" and `entry.get("role") in _MESSAGE_ROLES {
            content = `entry.get("content");
            if isinstance(content, list) {
                block_types: any = {b.get("type") for b in content if isinstance(b, dict)};
                if block_types & {"input_text", "output_text"} {
                    return RecordKind.MESSAGE;
                }
            }
            if isinstance(content, str) and content {
                return RecordKind.MESSAGE;
            }
        }
        return RecordKind.TOOL if typ in _TOOL_TYPES else RecordKind.OTHER;
    }

    def timestamp(record: str) -> str | None {
        try {
            value = json.loads(record).get("timestamp");
        } except (json.JSONDecodeError, AttributeError) {
            return None;
        }
        if isinstance(value, (int, float)) {
            seconds = value / 1000 if value > 100000000000.0 else value;
            return datetime.datetime.fromtimestamp(seconds, tz=datetime.UTC).isoformat();
        }
        return value if isinstance(value, str) else None;
    }
}
