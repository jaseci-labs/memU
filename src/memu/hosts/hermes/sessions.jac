import builtins;
import datetime;
import json;
import os;
import re;
import sqlite3;
import sys;
import from pathlib { Path }
import from typing { ClassVar }
glob DELIVERY_PATTERN = re.compile(
         "<!-- memu-hermes-retrieval:([0-9a-f]{32}) -->\\n.*?\\n<!-- /memu-hermes-retrieval:\\1 -->",
         re.DOTALL,
     ),
     STATE_DB = "~/.hermes/state.db";
def hermes_home -> Path;
def state_db_path -> Path;
glob _MESSAGE_ROLES = ("user", "assistant"),
     _ROW_COLUMNS = ("role", "content", "tool_call_id", "tool_calls", "tool_name", "timestamp");

class HermesTranscriptSource(TranscriptSource) {
    has _db: any;
    static has name: ClassVar[str] = "hermes";
    def init(state_db: str | Path | None = None);
    def `root -> Path;
    def exists -> bool;
    def key(path: Path) -> str;
    def session_id(path: Path) -> str;
    def _connect -> sqlite3.Connection;
    def discover -> list[Path];
    def read_records(path: Path) -> list[str];
    def classify(record: str) -> RecordKind;
    def sanitize(path: Path, record: str) -> str;
    def timestamp(record: str) -> str | None;
}
