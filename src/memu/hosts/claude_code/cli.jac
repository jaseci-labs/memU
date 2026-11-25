import importlib;
import argparse;
import platform;
import sys;
import from typing { Any, Optional }
glob HOST = "claude-code",
     CLAUDE_MD = "~/.claude/CLAUDE.md",
     SKILLS_DIR = "~/.claude/skills",
     SESSION_ID_ENV = "CLAUDE_CODE_SESSION_ID";

async def _cmd_legacy_schedule(args: argparse.Namespace) -> int {
    if platform.system() == "Darwin" {
        macos = importlib.import_module("memu.hosts.scheduling.macos");
        return macos.cleanup(remove=args.action == "uninstall");
    }
    if args.action == "status" {
        print("Legacy schedule status is verified only on macOS.", file=sys.stderr);
        return 1;
    }
    if platform.system() != "Windows" {
        print(
            "Remove previously configured cron/launchd memU schedules manually. No scheduled tasks were inspected or removed.",
            file=sys.stderr,
        );
        return 1;
    }
    scheduling = importlib.import_module("memu.hosts.scheduling");
    return scheduling.uninstall(SPEC, Layout.default(host=HOST, base=args.base_dir));
}

def _register_extra(sub: Any) {
    auth.register(sub);
    install.register(sub);
    uninstall.register(sub);
    cowork_cmd.register(sub);
    prompt_hook.register(sub);
    memorize_hook.register(sub);
    p = sub.add_parser(
        "schedule",
        help="Inspect/remove legacy schedules (macOS status/uninstall; Windows uninstall)",
    );
    p.add_argument(
        "action",
        choices=("status", "uninstall") if platform.system() == "Darwin" else ("uninstall",),
    );
    p.add_argument("--base-dir", default=SPEC.default_base_dir, help="memU working directory");
    p.set_defaults(handler=_cmd_legacy_schedule);
}

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

def main(argv: Optional[list[str]] = None) -> int {
    return run(SPEC, argv);
}

with entry:__main__ {
    sys.exit(main());
}
