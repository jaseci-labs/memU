import from pathlib { Path }
import from typing { ClassVar }

class ClaudeDesktopTranscriptSource(TranscriptSource) {
    has _cowork: any,
        _code: any;
    static has name: ClassVar[str] = "claude-code";
    def init(session_dir: str | Path, cowork_roots: list[str | Path] | None = None);
    def `root -> Path;
    def exists -> bool;
    def _source(path: Path) -> TranscriptSource;
    def discover -> list[Path];
    def read_records(path: Path) -> list[str];
    def read_incremental(path: Path, previous: dict[str, object] | None) -> TranscriptRead;
    def classify(record: str) -> RecordKind;
    def sanitize(path: Path, record: str) -> str;
    def timestamp(record: str) -> str | None;
    def key(path: Path) -> str;
    def scan_region(path: Path) -> str;
    def session_id(path: Path) -> str;
}
