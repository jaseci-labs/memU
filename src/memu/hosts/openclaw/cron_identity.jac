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
    def init(field: str) {
        super.init(f"{field} must contain only letters, digits, '.', '_', or '-'");
    }
}

def _session_key_segment(name: str, value: object) -> str {
    if not isinstance(value, str) {
        raise InvalidCronRegistration(name);
    }
    value = value.strip();
    if not re.fullmatch("[A-Za-z0-9._-]+", value) {
        raise InvalidCronRegistration(name);
    }
    return value;
}

def registration_path(base: str | Path) -> Path {
    return Path(base).expanduser() / _REGISTRATION_FILE;
}

def save_registration(path: Path, *, job_id: str) -> CronRegistration {
    registration = CronRegistration(job_id=_session_key_segment("job_id", job_id));
    path.parent.mkdir(parents=True, exist_ok=True);
    path.write_text(json.dumps({"job_id": registration.job_id}, indent=2), encoding="utf-8");
    return registration;
}

def load_registration(path: Path) -> CronRegistration | None {
    try {
        value = json.loads(path.read_text(encoding="utf-8"));
        if not isinstance(value, dict) {
            return None;
        }
        return CronRegistration(job_id=_session_key_segment("job_id", value.get("job_id", "")));
    } except (OSError, json.JSONDecodeError, ValueError) {
        return None;
    }
}

def resolve_session_ids(
    source: OpenClawTranscriptSource, registration: CronRegistration
) -> list[str] {
    return source.cron_run_session_ids(job_id=registration.job_id);
}

def _warning_path(layout: Layout) -> Path {
    return layout.base / _WARNING_STATE_FILE;
}

def _warn_once(layout: Layout, kind: str, message: str) {
    path = _warning_path(layout);
    try {
        current = path.read_text(encoding="utf-8").strip();
    } except OSError {
        current = "";
    }
    if current == kind {
        return;
    }
    logger.warning(message);
    try {
        path.parent.mkdir(parents=True, exist_ok=True);
        path.write_text(kind, encoding="utf-8");
    } except OSError {}
}

def _clear_warning(layout: Layout) {
    with contextlib.suppress(OSError) {
        _warning_path(layout).unlink();
    }
}

def _remember_all(path: Path, session_ids: list[str]) -> list[str] {
    remembered = self_sessions.load(path);
    merged = list(dict.fromkeys([*remembered, *session_ids]));
    if merged != remembered {
        path.parent.mkdir(parents=True, exist_ok=True);
        path.write_text(json.dumps(merged, indent=2), encoding="utf-8");
    }
    return merged;
}

def resolve_registered_sessions(source: TranscriptSource, layout: Layout) -> list[str] {
    remembered = self_sessions.load(layout.self_sessions);
    if not isinstance(source, OpenClawTranscriptSource) {
        return remembered;
    }
    registration = load_registration(registration_path(layout.base));
    if not source.supports_cron_run_identity() {
        _warn_once(
            layout,
            "unsupported-store",
            f"structured cron session exclusion requires OpenClaw {_MIN_OPENCLAW_VERSION} or newer. The ordinary bridging pipeline will continue unchanged, but this run's transcript cannot be excluded. Upgrading to a prerelease is optional. This warning is shown once until the condition recovers.",
        );
        return remembered;
    }
    if registration is None {
        _warn_once(
            layout,
            "missing-registration",
            "no OpenClaw bridging cron job is registered; run `memu-openclaw register-cron-job --job-id <jobId>`. Prepare will continue, but this run's transcript cannot be excluded. This warning is shown once until the condition recovers.",
        );
        return remembered;
    }
    resolved = resolve_session_ids(source, registration);
    if not resolved {
        _warn_once(
            layout,
            "no-matching-sessions",
            f"no sessions matched registered OpenClaw cron job {registration.job_id} in any agent store. Prepare will continue, but this run's transcript cannot be excluded. This warning is shown once until the condition recovers.",
        );
        return remembered;
    }
    _clear_warning(layout);
    return _remember_all(layout.self_sessions, resolved);
}
