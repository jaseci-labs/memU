import hashlib;
import json;
import os;
import sys;
import from collections.abc { Iterable }
import from pathlib { Path }
import from typing { ClassVar }
glob _AUDIT_DIR = "local-agent-mode-sessions",
     _ROOTS_ENV = "MEMU_COWORK_ROOTS";
def _existing_roots(candidates: Iterable[str | Path]) -> list[Path];
def _override_roots(value: str) -> list[Path];
def windows_data_roots -> list[Path];
def macos_data_roots -> list[Path];
def linux_data_roots -> list[Path];
def platform_data_roots -> list[Path];
def _default_root -> Path;

class CoworkTranscriptSource(TranscriptSource) {
    has _roots: any;
    static has name: ClassVar[str] = "cowork";
    def init(roots: Iterable[str | Path] | None = None);
    def `root -> Path;

    has roots: tuple[Path, ...] {
        getter {
            return self._roots;
        }
    }

    def exists -> bool;
    def discover -> list[Path];
    def key(path: Path) -> str;
    def session_id(path: Path) -> str;
    def read_records(path: Path) -> list[str];
    def classify(record: str) -> RecordKind;
    static def _normalize(raw: str) -> str | None;
}
