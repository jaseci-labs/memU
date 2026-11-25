impl stream_agent(argv: list[str], layout: Layout, prompt: str, timeout: int) {
    registered: set[str] = set();
    def capture(line: str) {
        session_id: object;
        if line.startswith("Session: ") {
            session_id = line.removeprefix("Session: ").strip();
            if session_id and session_id not in registered {
                self_sessions.remember(layout.self_sessions, session_id);
                registered.add(session_id);
            }
            return;
        }
        try {
            event = json.loads(line);
        } except ValueError {
            return;
        }
        if not isinstance(event, dict) or event.get("type") not in {"system", "result"} {
            return;
        }
        session_id = event.get("session_id");
        if isinstance(session_id, str) and session_id.strip() and (session_id not in registered) {
            self_sessions.remember(layout.self_sessions, session_id);
            registered.add(session_id);
        }
    }
    worker.stream_agent(
        [*argv, "--format", "stream-json", "-Q", "-q", prompt],
        layout,
        "",
        timeout,
        env=dict(os.environ, MEMU_BRIDGING_RUN="1", HERMES_HOME=str(hermes_home())),
        on_output=capture,
        stdin=subprocess.DEVNULL,
    );
    if not registered {
        raise RuntimeError("Hermes worker did not report a session_id; cannot exclude its history");
    }
}
