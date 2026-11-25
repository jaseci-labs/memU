import sys;
import from typing { Any, Optional }
glob HOST = "pi",
     AGENTS_MD = f"{AGENT_DIR}/AGENTS.md",
     SKILLS_DIR = f"{AGENT_DIR}/skills";
def _register_extra(sub: Any);
glob SPEC: any;

with entry {
    SPEC = HostSpec(
        host=HOST,
        display="pi",
        package="memu.hosts.pi",
        task_name="memu-bridging-pi",
        source_factory=PiTranscriptSource,
        session_dir=SESSION_DIR,
        session_help="pi v3 JSONL session directory (one directory per encoded cwd)",
        instruction_path=AGENTS_MD,
        skills_dir=SKILLS_DIR,
        schedule_backend="os",
        schedule_command="pi -p {prompt}",
        session_id_env="PI_SESSION_ID",
        hook=hooks.HookSpec(
            agent=hooks.HeadlessAgent(
                argv=(
                    "pi",
                    "-p",
                    "--no-session",
                    "--offline",
                    "--no-extensions",
                    "--no-skills",
                    "--no-prompt-templates",
                    "--no-context-files",
                ),
            ),
            stream_output=memorize_hook.stream_agent,
        ),
        register_extra=_register_extra,
    );
}

def main(argv: Optional[list[str]] = None) -> int;

with entry:__main__ {
    sys.exit(main());
}
