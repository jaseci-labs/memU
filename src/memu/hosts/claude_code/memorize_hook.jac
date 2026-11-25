import importlib;
import argparse;
import contextlib;
import json;
import os;
import subprocess;
import sys;
import from collections.abc { Iterator }
import from pathlib { Path }
import from typing { Any }
import from uuid { uuid4 }
glob BACKGROUND_ENV = "MEMU_CLAUDE_MEMORIZE",
     SESSION_ENV = "CLAUDE_CODE_SESSION_ID";

@contextlib.contextmanager
def memorize_run(layout: Layout) -> Iterator[bool] {
    with admission.memorize_run(
        layout,
        env={BACKGROUND_ENV: "1", SESSION_ENV: str(uuid4()), self_sessions.BRIDGING_RUN_ENV: "1"},
    ) as admitted {
        yield admitted;
    }
}

def stream_agent(argv: list[str], layout: Layout, prompt: str, timeout: int) {
    session_id = os.environ[SESSION_ENV];
    self_sessions.remember(layout.self_sessions, session_id);
    env = cli_prepare.standalone_env();
    env[SESSION_ENV] = session_id;
    worker.stream_agent([*argv, "--session-id", session_id], layout, prompt, timeout, env=env);
}

def launch_background(args: argparse.Namespace) -> Path {
    layout = Layout.default("claude-code", args.base_dir);
    layout.base.mkdir(parents=True, exist_ok=True);
    log_path = worker.new_log_path(layout.base).resolve();
    env = cli_prepare.standalone_env();
    worker.spawn_detached(
        "memu.hosts.claude_code.memorize_hook",
        [
            "--base-dir",
            str(layout.base.resolve()),
            "--session-dir",
            str(Path(args.session_dir).expanduser().resolve()),
            "--agent",
            args.agent,
            "--log-path",
            str(log_path),
        ],
        cwd=layout.base,
        env=env,
    );
    return log_path;
}

async def _cmd_memorize_hook(args: argparse.Namespace) -> int {
    try {
        event = json.load(sys.stdin);
        if not isinstance(event, dict) or event.get("hook_event_name") != "UserPromptSubmit" {
            raise ValueError("expected a UserPromptSubmit object");
        }
        if not is_automatic(event) and os.environ.get(BACKGROUND_ENV) != "1" {
            args.agent = str(cli_prepare.find_executable());
            launch_background(args);
        }
    } except (OSError, ValueError, TypeError) as exc {
        print(f"memU memorize hook failed: {exc}", file=sys.stderr);
    }
    print("{}");
    return 0;
}

def register(sub: Any) {
    SESSION_DIR = importlib.import_module("memu.hosts.claude_code.sessions").SESSION_DIR;
    parser = sub.add_parser(
        "memorize-hook", help="Start background memory processing on Claude prompt submission"
    );
    parser.add_argument("--base-dir", default="~/.memu/hosts/claude-code");
    parser.add_argument("--session-dir", default=SESSION_DIR);
    parser.add_argument("--agent", help=argparse.SUPPRESS);
    parser.set_defaults(handler=_cmd_memorize_hook);
}

def main -> int {
    claude_main = importlib.import_module("memu.hosts.claude_code.cli").main;
    parser = argparse.ArgumentParser();
    parser.add_argument("--base-dir", required=True);
    parser.add_argument("--session-dir", required=True);
    parser.add_argument("--agent", required=True);
    parser.add_argument("--log-path", required=True);
    args = parser.parse_args();
    return worker.run_logged(
        host="claude-code",
        log_path=args.log_path,
        run=lambda -> int {
            claude_main([
                "hook-run",
                "--base-dir",
                args.base_dir,
                "--session-dir",
                args.session_dir,
                "--agent",
                args.agent,
            ])
        },
    );
}

with entry:__main__ {
    sys.exit(main());
}
