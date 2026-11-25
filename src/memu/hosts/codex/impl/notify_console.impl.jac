impl _Tee.init(terminal: TextIO, log: TextIO) {
    self.terminal = terminal;
    self.log = log;
    if isinstance(terminal, io.TextIOWrapper) {
        terminal.reconfigure(errors="backslashreplace");
    }
}

impl _Tee.write(text: str) -> int {
    self.log.write(text);
    self.terminal.write(text);
    self.flush();
    return len(text);
}

impl _Tee.flush {
    if not self.terminal.closed {
        self.terminal.flush();
    }
    if not self.log.closed {
        self.log.flush();
    }
}

impl launch_background(argv: list[str], layout: Layout, label: str) -> Path {
    layout.base.mkdir(parents=True, exist_ok=True);
    interpreter = str(Path(sys.executable).with_name("python.exe"))
        if sys.platform == "win32"
        else sys.executable;
    flags = 0;
    if sys.platform == "win32" {
        flags = subprocess.CREATE_NO_WINDOW;
    }
    log_path = _new_log_path(layout.base).resolve();
    subprocess.Popen(
        [
            interpreter,
            "-u",
            "-m",
            __name__,
            "--label",
            label,
            "--background",
            "--log-path",
            str(log_path),
            "--",
            *argv,
        ],
        cwd=layout.base,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=sys.platform != "win32",
        creationflags=flags,
    );
    return log_path;
}

impl launch(argv: list[str], layout: Layout, label: str, hold: bool) {
    layout.base.mkdir(parents=True, exist_ok=True);
    interpreter = str(Path(sys.executable).with_name("python.exe"))
        if sys.platform == "win32"
        else sys.executable;
    command = [interpreter, "-u", "-m", __name__, "--label", label];
    if hold {
        command.append("--hold");
    }
    command += ["--", *argv];
    if sys.platform == "win32" {
        subprocess.Popen(command, cwd=layout.base, creationflags=subprocess.CREATE_NEW_CONSOLE);
    } elif sys.platform == "darwin" {
        script = "tell application \"Terminal\" to do script " + json.dumps(shlex.join(command));
        subprocess.run(["osascript", "-e", script], check=True);
    } else {
        terminal = shutil.which("x-terminal-emulator") or shutil.which("xterm");
        if not terminal {
            raise RuntimeError("Diagnostic mode needs x-terminal-emulator or xterm");
        }
        subprocess.Popen([terminal, "-e", *command], cwd=layout.base, start_new_session=True);
    }
}

impl _new_log_path(base: Path, hook: str = "memorize") -> Path {
    return worker.new_log_path(base, hook);
}

impl _remember_thread(line: str, layout: Layout) {
    try {
        event = json.loads(line);
    } except json.JSONDecodeError {
        return;
    }
    if not isinstance(event, dict) or event.get("type") != "thread.started" {
        return;
    }
    thread_id = event.get("thread_id");
    if not isinstance(thread_id, str) {
        return;
    }
    try {
        session_id = str(UUID(thread_id));
    } except ValueError {
        return;
    }
    self_sessions.remember(layout.self_sessions, session_id);
}

impl stream_agent(argv: list[str], layout: Layout, prompt: str, timeout: int) {
    env = os.environ.copy();
    env["MEMU_CODEX_MEMORIZE"] = "1";
    worker.stream_agent(
        argv,
        layout,
        prompt,
        timeout,
        env=env,
        on_output=lambda (line: any) -> any { _remember_thread(line, layout) },
    );
}

impl memorize_run(layout: Layout) -> Iterator[bool] {
    with admission.memorize_run(layout, cooldown_seconds=COOLDOWN_SECONDS) as admitted {
        yield admitted;
    }
}

impl main -> int {
    parser = argparse.ArgumentParser();
    parser.add_argument("--label", required=True);
    parser.add_argument("--hold", action="store_true");
    parser.add_argument("--background", action="store_true");
    parser.add_argument("--log-path", type=Path);
    parser.add_argument("command", nargs=argparse.REMAINDER);
    args = parser.parse_args();
    command = args.command[1:];
    base = Path(command[command.index("--base-dir") + 1]).expanduser();
    log_path = args.log_path or _new_log_path(base);
    def `report(message: str) {
        message = f"[{time.strftime('%Y-%m-%d %H:%M:%S%z')}] {message}";
        with log_path.open("a", encoding="utf-8") as log {
            log.write(message + "\n");
        }
        if not args.background {
            print(message, flush=True);
        }
    }
    code = 1;
    `report(f"=== WORKER {args.label} pid={os.getpid()} ===");
    `report(f"worker parent={os.getppid()} source={__file__}");
    try {
        import from memu.hosts.codex.cli { main as codex_main }
        with log_path.open("a", encoding="utf-8", buffering=1) as log, contextlib.redirect_stdout(
            log if args.background else cast(TextIO, _Tee(sys.stdout, log))
        ), contextlib.redirect_stderr(
            log if args.background else cast(TextIO, _Tee(sys.stderr, log))
        ) {
            code = codex_main(command);
            if code {
                print("=== MEMORIZE status=failed ===", flush=True);
            }
        }
    } except Exception {
        `report("=== MEMORIZE status=failed ===");
        `report(traceback.format_exc());
    } finally {
        `report(f"=== FINISHED {args.label} exit={code} ===");
        if args.hold {
            with contextlib.suppress(EOFError) {
                builtins.input("Press Enter to close this diagnostic session...");
            }
        }
    }
    return code;
}
