import datetime;
import json;
import logging;
import os;
import re;
import sqlite3;
import from pathlib { Path }
import from typing { ClassVar, Optional }
glob logger = logging.getLogger(__name__),
     SESSION_DIR = "~/.openclaw/agents",
     _MESSAGE_ROLES = ("user", "assistant"),
     _RECORD_PRIVATE_FIELDS = frozenset({"id", "parentId", "timestamp"}),
     _MESSAGE_PRIVATE_FIELDS = frozenset({
         "__openclaw",
         "api",
         "errorBody",
         "errorCode",
         "errorMessage",
         "errorType",
         "idempotencyKey",
         "model",
         "openclawDeliveryMirror",
         "provider",
         "responseId",
         "stopReason",
         "timestamp",
         "usage",
     }),
     _TOOL_RESULT_PRIVATE_FIELDS = frozenset({"details"}),
     _BLOCK_PRIVATE_FIELDS = frozenset({"partialArgs", "textSignature", "thinkingSignature"});
def _drop_known_fields(value: dict[object, object], fields: frozenset[str]) -> bool;
glob _SIDECAR_MARKERS = (".trajectory.", ".checkpoint."),
     _STORE_SUBDIR = "agent",
     _STORE_NAME = "openclaw-agent.sqlite",
     _IMPORT_ARCHIVE_DIR = "session-sqlite-import-archive",
     _SESSION_SUFFIX = ".jsonl";

class OpenClawTranscriptSource(TranscriptSource) {
    has _stored_paths: set[Path],
        _root: any;
    static has name: ClassVar[str] = "openclaw";
    def init(session_dir: str | Path = SESSION_DIR);
    def `root -> Path;
    def _databases -> list[Path];
    def _connect(db: Path) -> sqlite3.Connection;
    def _query(db: Path, sql: str, *args: object) -> list[tuple[any, ...]];
    def supports_cron_run_identity -> bool;
    def session_id(path: Path) -> str;
    def cron_run_session_ids(*, job_id: str) -> list[str];
    def _virtual_path(db: Path, session_id: str) -> Path;
    def _stored_session(path: Path) -> Optional[tuple[Path, str]];
    def discover -> list[Path];
    def read_records(path: Path) -> list[str];
    def read_incremental(path: Path, previous: Optional[dict[str, object]]) -> TranscriptRead;
    def sanitize(path: Path, record: str) -> str;
    def classify(record: str) -> RecordKind;
    def timestamp(record: str) -> str | None;
}
