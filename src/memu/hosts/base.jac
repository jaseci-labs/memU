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

    def init(path: Path, cause: BaseException) {
        self.path = path;
        self.cause = cause;
        super.init(f"could not read transcript data from {path}: {cause}");
    }
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

    def sanitize(path: Path, record: str) -> str {
        return record;
    }

    def exists -> bool {
        return self.root().is_dir();
    }

    def discover -> list[Path] {
        `root = self.root();
        if not `root.is_dir() {
            return [];
        }
        files = [path for path in `root.rglob("*.jsonl") if path.is_file()];
        files.sort(key=lambda (path: any) -> any { path.stat().st_mtime }, reverse=True);
        return files;
    }

    def read_records(path: Path) -> list[str] {
        with path.open(encoding="utf-8") as handle {
            return [line for line in (raw.strip() for raw in handle) if line];
        }
    }

    def read_incremental(path: Path, previous: Optional[dict[str, object]]) -> TranscriptRead {
        records = self.read_records(path);
        start = previous.get("lines", 0) if previous else 0;
        if not isinstance(start, int) {
            start = 0;
        }
        return TranscriptRead(records=records, start=start, cursor={"lines": len(records)});
    }

    def timestamp(record: str) -> str | None {
        try {
            value = json.loads(record).get("timestamp");
        } except (json.JSONDecodeError, AttributeError) {
            return None;
        }
        return value if isinstance(value, str) else None;
    }

    def key(path: Path) -> str {
        return path.relative_to(self.root()).as_posix();
    }

    def scan_region(path: Path) -> str {
        return "default";
    }

    def session_id(path: Path) -> str {
        return path.stem;
    }
}

def _drop_known_fields(value: dict[object, object], fields: frozenset[str]) -> bool {
    changed = False;
    for field in fields {
        if field in value {
            del value[field];
            changed = True;
        }
    }
    return changed;
}

def sanitize_agent_record(
    record: str,
    *,
    record_fields: frozenset[str],
    message_fields: frozenset[str],
    tool_result_fields: frozenset[str],
    block_fields: frozenset[str],
) -> str {
    try {
        `entry = json.loads(record);
    } except json.JSONDecodeError {
        return record;
    }
    if not isinstance(`entry, dict) {
        return record;
    }
    changed = _drop_known_fields(`entry, record_fields);
    message = `entry.get("message");
    if not isinstance(message, dict) {
        return json.dumps(`entry, ensure_ascii=False) if changed else record;
    }
    changed |= _drop_known_fields(message, message_fields);
    if message.get("role") == "toolResult" {
        changed |= _drop_known_fields(message, tool_result_fields);
    }
    content = message.get("content");
    if isinstance(content, list) {
        for block in content {
            if isinstance(block, dict) {
                changed |= _drop_known_fields(block, block_fields);
            }
        }
    }
    return json.dumps(`entry, ensure_ascii=False) if changed else record;
}
