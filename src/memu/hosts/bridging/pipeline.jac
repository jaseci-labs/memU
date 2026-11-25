import importlib;
import builtins;
import os;
import time;
import from collections.abc { Collection }
import from typing { Any }
glob build_agentic_memory_backend_from_env: any;

with entry {
    build_agentic_memory_backend_from_env = importlib.import_module(
        "memu.env"
    ).build_agentic_memory_backend_from_env;
}

glob MAX_JOBS = 10;
async def prepare(
    source: TranscriptSource,
    layout: Layout,
    *,
    verify_command: str,
    max_jobs: int = MAX_JOBS,
    skip_sessions: Collection[str] = (),
    host: str = "",
    session_id_env: str = "",
) -> int;
async def commit(layout: Layout) -> dict[str, Any];
