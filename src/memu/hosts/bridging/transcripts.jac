import json;
import logging;
import from collections.abc { Collection }
import from pathlib { Path }
glob logger = logging.getLogger(__name__);
def _split(source: TranscriptSource, path: Path, records: list[str]) -> tuple[list[str], list[str]];
def _last_timestamp(source: TranscriptSource, records: list[str]) -> str | None;
def prepare_transcripts(
    source: TranscriptSource,
    out_dir: Path,
    manifest_path: Path,
    max_jobs: int,
    pending_path: Path,
    skip_sessions: Collection[str] = (),
) -> int;
