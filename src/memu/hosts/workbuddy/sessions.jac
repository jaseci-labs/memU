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
    def init(session_dir: str | Path = SESSION_DIR);
    def `root -> Path;
    def classify(record: str) -> RecordKind;
    def timestamp(record: str) -> str | None;
}
