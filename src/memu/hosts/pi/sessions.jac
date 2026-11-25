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
def _drop_known_fields(value: dict[object, object], fields: frozenset[str]) -> bool;

class PiTranscriptSource(TranscriptSource) {
    has _root: any;
    static has name: ClassVar[str] = "pi";
    def init(session_dir: str | Path = SESSION_DIR);
    def `root -> Path;
    def session_id(path: Path) -> str;
    def sanitize(path: Path, record: str) -> str;
    def classify(record: str) -> RecordKind;
}
