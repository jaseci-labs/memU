impl memorize_run(layout: Layout) -> Iterator[bool] {
    with admission.memorize_run(layout) as admitted {
        if not admitted {
            yield False;
            return;
        }
        previous = {
            key: os.environ.get(key)
            for key in ("HERMES_SESSION_ID", self_sessions.BRIDGING_RUN_ENV)
        };
        os.environ.pop("HERMES_SESSION_ID", None);
        os.environ[self_sessions.BRIDGING_RUN_ENV] = "1";
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

impl launch(base: Path, session_id: str) -> Path {
    agent = shutil.which("hermes");
    if not agent {
        raise FileNotFoundError("hermes is not on PATH");
    }
    base = base.expanduser().resolve();
    base.mkdir(parents=True, exist_ok=True);
    log = worker.new_log_path(base).resolve();
    env = dict(os.environ, HERMES_HOME=str(hermes_home()), PYTHONIOENCODING="utf-8");
    for key in ("PYTHONPATH", "PYTHONHOME", "VIRTUAL_ENV", "HERMES_SESSION_ID") {
        env.pop(key, None);
    }
    subprocess.Popen(
        [
            sys.executable,
            "-u",
            "-m",
            "memu.hosts.hermes.memorize_hook",
            "--base-dir",
            str(base),
            "--agent",
            agent,
            "--log-path",
            str(log),
            "--origin-session",
            session_id,
        ],
        cwd=base,
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=sys.platform != "win32",
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
    );
    return log;
}

impl handle(args: argparse.Namespace) -> int {
    try {
        event = json.load(sys.stdin);
        if not isinstance(event, dict) or event.get("hook_event_name") != "on_session_end" {
            raise ValueError("Expected on_session_end event");
        }
        extra: any = event.get("extra") or dict[str, any]();
        session_id = event.get("session_id");
        if not isinstance(extra, dict) {
            raise TypeError("Expected event extra object");
        }
        if extra.get("completed") is not True
            or extra.get("failed")
            or extra.get("interrupted")
            or (not isinstance(session_id, str))
            or (not session_id.strip())
            or os.environ.get(self_sessions.BRIDGING_RUN_ENV, "").strip()
            or (
                session_id
                in self_sessions.load(Layout.default("hermes", args.base_dir).self_sessions)
            )
        {
            print("{}");
            return 0;
        }
        log = launch(Path(args.base_dir), session_id);
    } except (OSError, ValueError, TypeError) as exc {
        print(f"memU Hermes memorize hook failed: {exc}", file=sys.stderr);
        print("{}");
        return 1;
    }
    print(json.dumps({"log_path": str(log)}));
    return 0;
}

impl register(sub: Any) {
    parser = sub.add_parser(
        "memorize-hook", help="Launch detached memory processing after a completed Hermes turn"
    );
    parser.add_argument("--base-dir", default="~/.memu/hosts/hermes");
    parser.set_defaults(handler=handle);
}

impl main -> int {
    cli_main = importlib.import_module("memu.hosts.hermes.cli").main;
    parser = argparse.ArgumentParser();
    for name in ("base-dir", "agent", "log-path", "origin-session") {
        parser.add_argument(f"--{name}", required=True);
    }
    args = parser.parse_args();
    layout = Layout.default("hermes", args.base_dir);
    with Path(args.log_path).open(
        "a", encoding="utf-8", buffering=1
    ) as log, contextlib.redirect_stdout(log), contextlib.redirect_stderr(log) {
        print(f"=== WORKER hermes pid={os.getpid()} ===", flush=True);
        if args.origin_session in self_sessions.load(layout.self_sessions) {
            print("=== SKIPPED worker session ===", flush=True);
            return 0;
        }
        os.environ.pop("HERMES_SESSION_ID", None);
        os.environ[self_sessions.BRIDGING_RUN_ENV] = "1";
        try {
            code: int = cli_main([
                "hook-run",
                "--base-dir",
                str(layout.base),
                "--session-dir",
                str(state_db_path()),
                "--agent",
                args.agent,
            ]);
        } except Exception {
            traceback.print_exc();
            code = 1;
        }
        print(f"=== FINISHED hermes exit={code} ===", flush=True);
        return code;
    }
}
