import importlib;
import argparse;
import contextlib;
import json;
import os;
import shutil;
import subprocess;
import sys;
import from collections.abc { Iterator }
import from dataclasses { replace }
import from pathlib { Path }
import from typing { Any }
import from uuid { uuid4 }

@contextlib.contextmanager
def memorize_run(layout: Layout) -> Iterator[bool] {
    with admission.memorize_run(
        layout, env={"PI_SESSION_ID": str(uuid4()), self_sessions.BRIDGING_RUN_ENV: "1"}
    ) as admitted {
        yield admitted;
    }
}

def stream_agent(argv: list[str], layout: Layout, prompt: str, timeout: int) {
    worker.stream_agent(
        [*argv, prompt], layout, "", timeout, env=dict(os.environ), stdin=subprocess.DEVNULL
    );
}

def launch_background(args: argparse.Namespace, event: dict[str, Any]) -> Path {
    session_file = Path(event["session_file"]).expanduser().resolve(strict=True);
    if not session_file.is_file() or session_file.suffix != ".jsonl" {
        raise ValueError("Expected a persisted pi session file");
    }
    agent = shutil.which("pi");
    if not agent {
        raise FileNotFoundError("pi is not on PATH");
    }
    layout = Layout.default("pi", args.base_dir);
    layout.base.mkdir(parents=True, exist_ok=True);
    log_path = worker.new_log_path(layout.base).resolve();
    argv = [
        "--base-dir",
        str(layout.base.resolve()),
        "--session-dir",
        str(session_file.parent),
        "--agent",
        agent,
        "--log-path",
        str(log_path),
    ];
    for name in ("provider", "model") {
        value = event.get(name);
        if isinstance(value, str) and value.strip() {
            argv.extend([f"--{name}", value]);
        }
    }
    worker.spawn_detached(
        "memu.hosts.pi.memorize_hook", argv, cwd=layout.base, env=dict(os.environ)
    );
    return log_path;
}

async def _cmd_memorize_hook(args: argparse.Namespace) -> int {
    try {
        event = json.load(sys.stdin);
        if not isinstance(event, dict) or event.get("hook_event_name") != "agent_settled" {
            raise ValueError("Expected an agent_settled object");
        }
        if os.environ.get(self_sessions.BRIDGING_RUN_ENV, "").strip()
            or not event.get("session_file")
        {
            print("{}");
            return 0;
        }
        if not isinstance(event["session_file"], str) {
            raise TypeError("Expected session_file to be a path string");
        }
        log_path = launch_background(args, event);
    } except (OSError, ValueError, TypeError) as exc {
        print(f"memU memorize hook failed: {exc}", file=sys.stderr);
        print("{}");
        return 1;
    }
    print(json.dumps({"log_path": str(log_path)}));
    return 0;
}

def register(sub: Any) {
    parser = sub.add_parser(
        "memorize-hook", help="Start background memory processing after a pi user turn settles"
    );
    parser.add_argument("--base-dir", default="~/.memu/hosts/pi");
    parser.set_defaults(handler=_cmd_memorize_hook);
}

def main -> int {
    run = importlib.import_module("memu.hosts.host_cli").run;
    SPEC = importlib.import_module("memu.hosts.pi.cli").SPEC;
    parser = argparse.ArgumentParser();
    for name in ("base-dir", "session-dir", "agent", "log-path") {
        parser.add_argument(f"--{name}", required=True);
    }
    parser.add_argument("--provider");
    parser.add_argument("--model");
    args = parser.parse_args();
    if SPEC.hook is None {
        raise RuntimeError("pi memory hook is not configured");
    }
    argv: list[any] = list(SPEC.hook.agent.argv);
    for name in ("provider", "model") {
        if (value := getattr(args, name)) {
            argv.extend([f"--{name}", value]);
        }
    }
    spec = replace(SPEC, hook=replace(SPEC.hook, agent=hooks.HeadlessAgent(tuple(argv))));
    return worker.run_logged(
        host="pi",
        log_path=args.log_path,
        run=lambda -> int {
            run(
                spec,
                [
                    "hook-run",
                    "--base-dir",
                    args.base_dir,
                    "--session-dir",
                    args.session_dir,
                    "--agent",
                    args.agent,
                ],
            )
        },
    );
}

with entry:__main__ {
    sys.exit(main());
}
