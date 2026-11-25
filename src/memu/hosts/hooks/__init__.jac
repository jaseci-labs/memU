import shutil;
import subprocess;
import sys;
import from collections.abc { Callable }
import from dataclasses { dataclass }
import from pathlib { Path }

@dataclass(frozen=True)
class HeadlessAgent {
    has argv: tuple[str, ...],
        timeout_seconds: int = 60 * 60;
}

@dataclass(frozen=True)
class HookSpec {
    has agent: HeadlessAgent,
        stream_output: Callable[[list[str], Layout, str, int], None] | None = None;
}

def jobs_prompt(layout: Layout) -> str;
def pending_jobs(layout: Layout) -> list[Path];
def run_agent(
    agent: HeadlessAgent,
    layout: Layout,
    *,
    executable: str = "",
    stream_output: Callable[[list[str], Layout, str, int], None] | None = None,
);
