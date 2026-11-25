impl memorize_run(layout: Layout) -> Iterator[bool] {
    with admission.memorize_run(layout) as admitted {
        if not admitted {
            yield False;
            return;
        }
        updates = {
            BACKGROUND_ENV: "1",
            SESSION_ENV: str(uuid4()),
            self_sessions.BRIDGING_RUN_ENV: "1",
        };
        previous = {key: os.environ.get(key) for key in updates};
        os.environ.update(updates);
        try {
            yield True;
        } finally {
            for (key, value) in previous.items() {
                if value is None {
                    os.environ.pop(key, None);
                } else {
                    os.environ[key] = value;
                }
            }
        }
    }
}

impl stream_agent(argv: list[str], layout: Layout, prompt: str, timeout: int) {
    session_id = os.environ[SESSION_ENV];
    self_sessions.remember(layout.self_sessions, session_id);
    env = cli_prepare.standalone_env();
    env[SESSION_ENV] = session_id;
    worker.stream_agent([*argv, "--session-id", session_id], layout, prompt, timeout, env=env);
}

impl launch_background(args: argparse.Namespace) -> Path {
    layout = Layout.default("claude-code", args.base_dir);
    layout.base.mkdir(parents=True, exist_ok=True);
    log_path = worker.new_log_path(layout.base).resolve();
    env = cli_prepare.standalone_env();
    subprocess.Popen(
        [
            sys.executable,
            "-u",
            "-m",
            "memu.hosts.claude_code.memorize_hook",
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
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=sys.platform != "win32",
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0) if sys.platform == "win32" else 0,
    );
    return log_path;
}

impl _cmd_memorize_hook(args: argparse.Namespace) -> int {
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

impl register(sub: Any) {
    SESSION_DIR = importlib.import_module("memu.hosts.claude_code.sessions").SESSION_DIR;
    parser = sub.add_parser(
        "memorize-hook", help="Start background memory processing on Claude prompt submission"
    );
    parser.add_argument("--base-dir", default="~/.memu/hosts/claude-code");
    parser.add_argument("--session-dir", default=SESSION_DIR);
    parser.add_argument("--agent", help=argparse.SUPPRESS);
    parser.set_defaults(handler=_cmd_memorize_hook);
}

impl main -> int {
    claude_main = importlib.import_module("memu.hosts.claude_code.cli").main;
    parser = argparse.ArgumentParser();
    parser.add_argument("--base-dir", required=True);
    parser.add_argument("--session-dir", required=True);
    parser.add_argument("--agent", required=True);
    parser.add_argument("--log-path", required=True);
    args = parser.parse_args();
    code = 1;
    with Path(args.log_path).open(
        "a", encoding="utf-8", buffering=1
    ) as log, contextlib.redirect_stdout(log), contextlib.redirect_stderr(log) {
        print(f"=== WORKER claude-code pid={os.getpid()} ===", flush=True);
        try {
            code = claude_main([
                "hook-run",
                "--base-dir",
                args.base_dir,
                "--session-dir",
                args.session_dir,
                "--agent",
                args.agent,
            ]);
        } except Exception {
            traceback.print_exc();
        }
        if code {
            print("=== MEMORIZE status=failed ===", flush=True);
        }
        print(f"=== FINISHED claude-code exit={code} ===", flush=True);
    }
    return code;
}
