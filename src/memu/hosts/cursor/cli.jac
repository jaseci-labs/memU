import from typing { Optional }
import sys;
glob HOST = "cursor",
     SESSION_ID_ENV = "CURSOR_CONVERSATION_ID",
     AGENTS_MD = "./AGENTS.md";

with entry {}

glob SPEC = HostSpec(
    host=HOST,
    display="Cursor",
    package="memu.hosts.cursor",
    task_name="memu-bridging-cursor",
    source_factory=CursorTranscriptSource,
    session_dir=SESSION_DIR,
    session_help="Cursor agent-transcript root (one project dir per escaped cwd)",
    instruction_path=AGENTS_MD,
    schedule_backend="os",
    schedule_command="cursor-agent --trust -p {prompt}",
    session_id_env=SESSION_ID_ENV,
    needs_headless_auth=True,
    install_hint="""  Install the standalone Cursor Agent CLI:
    irm 'https://cursor.com/install?win32=true' | iex
    # macOS/Linux/WSL:  curl https://cursor.com/install -fsSL | bash
  Then re-run from a NEW terminal - this shell's PATH may predate the install.""",
    auth_hint="""    sign in to the Cursor IDE on this machine (the CLI reuses that account
    session), or run `cursor-agent login` once. Note: custom-provider (BYOK)
    models do not work in the CLI - runs bill the Cursor account's plan,""",
);
def main(argv: Optional[list[str]] = None) -> int;

with entry:__main__ {
    sys.exit(main());
}
