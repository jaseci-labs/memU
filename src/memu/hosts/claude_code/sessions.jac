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
    def init(session_dir: str | Path = SESSION_DIR);
    def `root -> Path;
    def session_id(path: Path) -> str;
    def classify(record: str) -> RecordKind;
    def sanitize(path: Path, record: str) -> str;
}
