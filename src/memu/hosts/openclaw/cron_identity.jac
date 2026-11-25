import contextlib;
import json;
import logging;
import re;
import from dataclasses { dataclass }
import from pathlib { Path }
glob logger = logging.getLogger(__name__),
     _REGISTRATION_FILE = ".cron_job.openclaw.json",
     _WARNING_STATE_FILE = ".cron_identity_warning.openclaw",
     _MIN_OPENCLAW_VERSION = "v2026.7.2-beta.4";

@dataclass(frozen=True)
class CronRegistration {
    has job_id: str;
}

class InvalidCronRegistration(ValueError) {
    def init(field: str);
}

def _session_key_segment(name: str, value: object) -> str;
def registration_path(base: str | Path) -> Path;
def save_registration(path: Path, *, job_id: str) -> CronRegistration;
def load_registration(path: Path) -> CronRegistration | None;
def resolve_session_ids(
    source: OpenClawTranscriptSource, registration: CronRegistration
) -> list[str];
def _warning_path(layout: Layout) -> Path;
def _warn_once(layout: Layout, kind: str, message: str);
def _clear_warning(layout: Layout);
def _remember_all(path: Path, session_ids: list[str]) -> list[str];
def resolve_registered_sessions(source: TranscriptSource, layout: Layout) -> list[str];
