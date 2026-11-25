import json;
import from abc { ABC, abstractmethod }
import from dataclasses { dataclass }
import from enum { Enum }
import from pathlib { Path }
import from typing { ClassVar, Optional }

class RecordKind(Enum) {
    static has MESSAGE: any = "message",
               TOOL: any = "tool",
               OTHER: any = "other";
}

class TranscriptReadError(RuntimeError) {
    has cause: BaseException,
        path: Path;
    def init(path: Path, cause: BaseException);
}

@dataclass(frozen=True)
class TranscriptRead {
    has records: list[str],
        start: int,
        cursor: dict[str, object];

    has changed: bool {
        getter {
            return len(self.records) > self.start;
        }
    }
}

class TranscriptSource(ABC) {
    has name: ClassVar[str];
    def `root -> Path abst;
    def classify(record: str) -> RecordKind abst;
    def sanitize(path: Path, record: str) -> str;
    def exists -> bool;
    def discover -> list[Path];
    def read_records(path: Path) -> list[str];
    def read_incremental(path: Path, previous: Optional[dict[str, object]]) -> TranscriptRead;
    def timestamp(record: str) -> str | None;
    def key(path: Path) -> str;
    def scan_region(path: Path) -> str;
    def session_id(path: Path) -> str;
}

def _drop_known_fields(value: dict[object, object], fields: frozenset[str]) -> bool;
def sanitize_agent_record(
    record: str,
    *,
    record_fields: frozenset[str],
    message_fields: frozenset[str],
    tool_result_fields: frozenset[str],
    block_fields: frozenset[str],
) -> str;
