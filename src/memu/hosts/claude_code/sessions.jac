import json;
import os;
import from pathlib { Path }
import from typing { ClassVar }
glob SESSION_DIR = "~/.claude/projects",
     _RECORD_PRIVATE_FIELDS = frozenset({
         "attributionMcpServer",
         "attributionMcpTool",
         "attributionSkill",
         "cwd",
         "effort",
         "entrypoint",
         "gitBranch",
         "isCompactSummary",
         "isMeta",
         "isSidechain",
         "isVisibleInTranscriptOnly",
         "origin",
         "parentUuid",
         "permissionMode",
         "promptId",
         "promptSource",
         "sessionId",
         "sourceToolAssistantUUID",
         "sourceToolUseID",
         "timestamp",
         "toolDenialKind",
         "toolUseResult",
         "userType",
         "uuid",
         "version",
     }),
     _MESSAGE_PRIVATE_FIELDS = frozenset({"id", "model", "stop_details", "stop_reason", "usage"});

class ClaudeCodeTranscriptSource(TranscriptSource) {
    has _root: any;
    static has name: ClassVar[str] = "claude-code";

    def init(session_dir: str | Path = SESSION_DIR) {
        self._root = Path(os.path.expanduser(str(session_dir)));
    }

    def `root -> Path {
        return self._root;
    }

    def session_id(path: Path) -> str {
        parts = path.relative_to(self.root()).parts;
        return parts[1] if len(parts) > 2 else path.stem;
    }

    def classify(record: str) -> RecordKind {
        return classify_claude_record(record);
    }

    def sanitize(path: Path, record: str) -> str {
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
}
