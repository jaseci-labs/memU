import from typing { Optional }
import importlib;
import argparse;
import sys;
glob HOST = "codex",
     VERIFY_COMMAND = "memu-codex verify-resources",
     AGENTS_MD = "~/.codex/AGENTS.md",
     SKILLS_DIR = "~/.codex/skills",
     HOOK = hooks.HookSpec(
         agent=hooks.HeadlessAgent(
             argv=(
                 "codex",
                 "exec",
                 "-c",
                 "notify=[]",
                 "--json",
                 "--skip-git-repo-check",
                 "--dangerously-bypass-approvals-and-sandbox",
                 "-C",
                 "{base}",
                 "-",
             ),
         ),
         stream_output=notify_console.stream_agent,
     );

def _register_extra(sub: object) {
    install.register(sub);
    uninstall.register(sub);
    cli_prepare.register(sub);
    prompt_hook.register(sub);
    memorize_hook.register(sub);
    prompt_hook_install.register(sub);
}

glob SPEC: any;

with entry {
    SPEC = HostSpec(
        host=HOST,
        display="Codex",
        package="memu.hosts.codex",
        task_name="memu-bridging-codex",
        former_task_names=("memu-remember", "memu-bridging"),
        source_factory=CodexTranscriptSource,
        session_dir=SESSION_DIR,
        session_help="Codex session log",
        instruction_path=AGENTS_MD,
        skills_dir=SKILLS_DIR,
        schedule_backend="native",
        hook=HOOK,
        install_hint="""Install the standalone Codex CLI using the official native installer:
  Windows (PowerShell): irm https://chatgpt.com/codex/install.ps1 | iex
  macOS/Linux: curl -fsSL https://chatgpt.com/codex/install.sh | sh
Refresh PATH, verify `codex --version`, then retry `memu-codex install-prompt-hook`.""",
        register_extra=_register_extra,
    );
}

def build_parser -> argparse.ArgumentParser {
    _build = importlib.import_module("memu.hosts.host_cli").build_parser;
    return _build(SPEC);
}

def main(argv: Optional[list[str]] = None) -> int {
    return run(SPEC, argv);
}

with entry:__main__ {
    sys.exit(main());
}
