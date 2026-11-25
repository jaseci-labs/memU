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
def _injected(payload: dict[any, any]) -> bool;

class CodexTranscriptSource(TranscriptSource) {
    has _root: any;
    static has name: ClassVar[str] = "codex";
    def init(session_dir: str | Path = SESSION_DIR);
    def `root -> Path;
    def session_id(path: Path) -> str;
    def sanitize(path: Path, record: str) -> str;
    def classify(record: str) -> RecordKind;
}
