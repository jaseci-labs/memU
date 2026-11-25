import json;
import os;
import from pathlib { Path }
import from typing { ClassVar }
glob SESSION_DIR = "~/.cursor/projects";

class CursorTranscriptSource(TranscriptSource) {
    has _root: any;
    static has name: ClassVar[str] = "cursor";
    def init(session_dir: str | Path = SESSION_DIR);
    def `root -> Path;
    def discover -> list[Path];
    def classify(record: str) -> RecordKind;
}
