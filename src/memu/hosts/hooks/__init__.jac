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

def jobs_prompt(layout: Layout) -> str {
    return f"Process the memU self-evolve jobs. List {layout.jobs}/*.txt and process them in ascending numeric order. Read each job and follow its instructions exactly. Finish one job before starting the next. Do not run memu-{layout.host} prepare or commit; the worker runs those commands itself.";
}

def pending_jobs(layout: Layout) -> list[Path] {
    return sorted(layout.jobs.glob("*.txt"));
}

def run_agent(
    agent: HeadlessAgent,
    layout: Layout,
    *,
    executable: str = "",
    stream_output: Callable[[list[str], Layout, str, int], None] | None = None,
) {
    argv = [token.replace("{base}", str(layout.base)) for token in agent.argv];
    resolved = executable or shutil.which(argv[0]);
    if not resolved {
        raise RuntimeError(f"`{argv[0]}` is not on PATH");
    }
    if stream_output is not None {
        stream_output([resolved, *argv[1:]], layout, jobs_prompt(layout), agent.timeout_seconds);
        return;
    }
    result = subprocess.run(
        [resolved, *argv[1:]],
        input=jobs_prompt(layout),
        text=True,
        encoding="utf-8",
        errors="replace",
        cwd=layout.base,
        capture_output=True,
        timeout=agent.timeout_seconds,
        check=False,
    );
    if result.stdout.strip() {
        print(result.stdout.strip()[-2000:]);
    }
    if result.stderr.strip() {
        print(result.stderr.strip()[-4000:], file=sys.stderr);
    }
    if result.returncode {
        raise RuntimeError(f"`{argv[0]}` exited {result.returncode}");
    }
}
