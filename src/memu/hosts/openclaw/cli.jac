import argparse;
import sys;
import from typing { Any, Optional }
glob HOST = "openclaw",
     AGENTS_MD = "~/.openclaw/workspace/AGENTS.md",
     SKILLS_DIR = "~/.openclaw/skills";

async def _cmd_register_cron_job(args: argparse.Namespace) -> int;
def _register_cron_job(sub: Any);
glob SPEC: any;

with entry {
    SPEC = HostSpec(
        host=HOST,
        display="OpenClaw",
        package="memu.hosts.openclaw",
        task_name="memu-bridging-openclaw",
        former_task_names=("memu-remember", "memu-bridging"),
        source_factory=OpenClawTranscriptSource,
        session_dir=SESSION_DIR,
        session_help="OpenClaw agents dir holding each agent's transcript store (SQLite, or legacy sessions/*.jsonl)",
        instruction_path=AGENTS_MD,
        skills_dir=SKILLS_DIR,
        register_extra=_register_cron_job,
        resolve_self_sessions=cron_identity.resolve_registered_sessions,
        schedule_backend="native",
    );
}

def main(argv: Optional[list[str]] = None) -> int;

with entry:__main__ {
    sys.exit(main());
}
