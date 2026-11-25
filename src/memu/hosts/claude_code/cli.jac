import importlib;
import argparse;
import platform;
import sys;
import from typing { Any, Optional }
glob HOST = "claude-code",
     CLAUDE_MD = "~/.claude/CLAUDE.md",
     SKILLS_DIR = "~/.claude/skills",
     SESSION_ID_ENV = "CLAUDE_CODE_SESSION_ID";

async def _cmd_legacy_schedule(args: argparse.Namespace) -> int;
def _register_extra(sub: Any);
glob SPEC: any;

with entry {
    SPEC = HostSpec(
        host=HOST,
        display="Claude Code",
        package="memu.hosts.claude_code",
        task_name="memu-bridging-claude-code",
        former_task_names=("memu-remember-claude-code",),
        source_factory=ClaudeDesktopTranscriptSource,
        session_dir=SESSION_DIR,
        session_help="Claude Code session log (one project dir per escaped cwd)",
        instruction_path=CLAUDE_MD,
        skills_dir=SKILLS_DIR,
        schedule_backend="hook",
        session_id_env=SESSION_ID_ENV,
        hook=hooks.HookSpec(
            agent=hooks.HeadlessAgent(argv=("claude", "-p", "--dangerously-skip-permissions")),
            stream_output=memorize_hook.stream_agent,
        ),
        register_extra=_register_extra,
        install_hint="""  Install a standalone claude:
    winget install Anthropic.ClaudeCode
    # or:  irm https://claude.ai/install.ps1 | iex
    # or:  npm install -g @anthropic-ai/claude-code""",
    );
}

def main(argv: Optional[list[str]] = None) -> int;

with entry:__main__ {
    sys.exit(main());
}
