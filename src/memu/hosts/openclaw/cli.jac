import argparse;
import sys;
import from typing { Any, Optional }
glob HOST = "openclaw",
     AGENTS_MD = "~/.openclaw/workspace/AGENTS.md",
     SKILLS_DIR = "~/.openclaw/skills";

async def _cmd_register_cron_job(args: argparse.Namespace) -> int {
    registration = cron_identity.save_registration(
        cron_identity.registration_path(args.base_dir), job_id=args.job_id
    );
    print(f"registered OpenClaw cron job {registration.job_id}");
    return 0;
}

def _register_cron_job(sub: Any) {
    parser = sub.add_parser(
        "register-cron-job",
        help="Record the exact OpenClaw cron job whose sessions prepare must skip",
    );
    parser.add_argument(
        "--job-id", required=True, help="OpenClaw cron job id returned at creation"
    );
    parser.add_argument("--base-dir", default="~/.memu/hosts/openclaw", help=argparse.SUPPRESS);
    parser.set_defaults(handler=_cmd_register_cron_job);
}

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

def main(argv: Optional[list[str]] = None) -> int {
    return run(SPEC, argv);
}

with entry:__main__ {
    sys.exit(main());
}
