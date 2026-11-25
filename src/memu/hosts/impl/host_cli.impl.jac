impl _task_names_text(names: tuple[str, ...]) -> str {
    return ", ".join((f"`{name}`" for name in names)) if names else "none";
}

impl _task_name_pattern(names: tuple[str, ...]) -> str {
    return "|".join((re.escape(name) for name in names));
}

impl HostSpec.postinit {
    if not _TASK_NAME_RE.fullmatch(self.task_name) {
        msg = f"invalid task_name: {self.task_name!r}";
        raise ValueError(msg);
    }
    if self.task_name in self.former_task_names {
        msg = "task_name must not also appear in former_task_names";
        raise ValueError(msg);
    }
    if len(set(self.former_task_names)) != len(self.former_task_names) {
        msg = "former_task_names must not contain duplicates";
        raise ValueError(msg);
    }
    if any((not name.strip() for name in self.former_task_names)) {
        msg = "former_task_names must not contain empty names";
        raise ValueError(msg);
    }
}

impl HostSpec.render_doc(text: str) -> str {
    values = {
        "task_name": self.task_name,
        "former_task_names": _task_names_text(self.former_task_names),
        "all_task_names": _task_names_text(self.all_task_names),
        "task_name_pattern": _task_name_pattern(self.all_task_names),
        "task_doc_name": self.task_doc_name,
    };
    unknown = {str(token) for token in _DOC_TOKEN_RE.findall(text)} - _DOC_TOKENS;
    if unknown {
        msg = f"unknown host-doc token(s): {', '.join(sorted(unknown))}";
        raise ValueError(msg);
    }
    rendered = _DOC_TOKEN_RE.sub(lambda (`match: any) -> any { values[`match.group(1)] }, text);
    if "{{" in rendered or "}}" in rendered {
        msg = "unresolved host-doc token";
        raise ValueError(msg);
    }
    return rendered;
}

impl _layout(spec: HostSpec, args: argparse.Namespace) -> Layout {
    return Layout.default(host=spec.host, base=args.base_dir);
}

impl _refresh_retrieval(spec: HostSpec) {
    skills_dir = Path(spec.skills_dir) if spec.skills_dir else None;
    try {
        for (target, changed) in instruction.refresh(
            Path(spec.instruction_path), spec.binary, skills_dir=skills_dir
        ) {
            if changed {
                print(f"refreshed the retrieval procedure at {target}");
            }
        }
    } except Exception as exc {
        print(f"note: could not refresh the retrieval procedure ({exc})", file=sys.stderr);
    }
}

impl _cmd_prepare(spec: HostSpec, args: argparse.Namespace) -> int {
    source = spec.source_factory(args.session_dir);
    if not source.exists() {
        print(f"error: no {spec.display} session log at {source.root()}", file=sys.stderr);
        return 2;
    }
    layout = _layout(spec, args);
    _mark_cycle_start(spec, layout);
    own_session = os.environ.get(spec.session_id_env, "").strip() if spec.session_id_env else "";
    skip_sessions = spec.resolve_self_sessions(source, layout)
        if spec.resolve_self_sessions is not None
        else self_sessions.load(layout.self_sessions);
    if not self_sessions.is_bridging_run(Path.cwd(), layout.base) {
        own_session = "";
    } elif spec.session_id_env and (not own_session) {
        print(
            f"warning: {spec.session_id_env} is unset, so this run cannot recognise its own session; it will be mined like any other",
            file=sys.stderr,
        );
    }
    if own_session and own_session not in skip_sessions {
        print(
            f"note: recording this session ({own_session}) as a bridging run; its transcript will not be mined. Undo by removing it from {layout.self_sessions}",
        );
    }
    if own_session {
        skip_sessions = self_sessions.remember(layout.self_sessions, own_session);
    }
    num_sessions = await prepare(
        source,
        layout,
        verify_command=f"{spec.verify_command} --base-dir {shlex.quote(str(layout.base))}",
        max_jobs=args.max_jobs,
        skip_sessions=skip_sessions,
        host=spec.host,
        session_id_env=spec.session_id_env,
    );
    num_jobs = 2 * num_sessions + 1 if num_sessions else 0;
    print(f"prepared {num_sessions} session(s) -> {num_jobs} job(s) in {layout.jobs}");
    if num_sessions == 0 {
        print("no new session turns since the last run; nothing to mine");
    }
    _refresh_retrieval(spec);
    events.flush();
    return 0;
}

impl _cmd_commit(spec: HostSpec, args: argparse.Namespace) -> int {
    layout = _layout(spec, args);
    session_count = _pending_session_count(layout);
    started = time.monotonic();
    try {
        result = await commit(layout);
    } except Exception {
        _record_commit(
            spec,
            layout,
            success=False,
            recall_files=0,
            resources=0,
            sessions=session_count,
            latency_ms=_elapsed_ms(started),
        );
        raise;
    }
    recall_files = result.get("recall_files", []);
    resources = result.get("resources", []);
    _record_commit(
        spec,
        layout,
        success=True,
        recall_files=len(recall_files),
        resources=len(resources),
        sessions=session_count,
        latency_ms=_elapsed_ms(started),
    );
    with contextlib.suppress(OSError) {
        layout.run_marker.unlink(missing_ok=True);
    }
    events.flush();
    if not recall_files and (not resources) {
        print("nothing to commit");
        return 0;
    }
    print(f"committed {len(recall_files)} recall file(s) and {len(resources)} resource(s)");
    for recall_file in recall_files {
        print(f"  - {recall_file.get('track')}/{recall_file.get('name')}");
    }
    return 0;
}

impl _pending_session_count(layout: Layout) -> int {
    try {
        return len(list(layout.sessions.glob("*.jsonl")));
    } except OSError {
        return 0;
    }
}

impl _elapsed_ms(started: float) -> int {
    return round((time.monotonic() - started) * 1000);
}

impl _mark_cycle_start(spec: HostSpec, layout: Layout) {
    try {
        layout.run_marker.parent.mkdir(parents=True, exist_ok=True);
        layout.run_marker.write_text(json.dumps({"started_at": time.time()}), encoding="utf-8");
    } except OSError {
        return;
    }
    events.record(events.MEMORY_UPDATE_STARTED, host=spec.host, session_id_env=spec.session_id_env);
}

impl _cycle_duration_ms(layout: Layout) -> int | None {
    try {
        started = json.loads(layout.run_marker.read_text(encoding="utf-8"))["started_at"];
        elapsed = time.time() - float(started);
    } except (OSError, ValueError, TypeError, KeyError) {
        return None;
    }
    if elapsed < 0 or elapsed > MAX_CYCLE_SECONDS {
        return None;
    }
    return round(elapsed * 1000);
}

impl _cycle_is_open(layout: Layout) -> bool {
    try {
        return layout.run_marker.is_file();
    } except OSError {
        return False;
    }
}

impl _record_commit(
    spec: HostSpec,
    layout: Layout,
    *,
    success: bool,
    recall_files: int,
    resources: int,
    sessions: int,
    latency_ms: int,
) {
    counts: dict[str, Any] = {
        "recall_file_count": recall_files,
        "resource_count": resources,
        "session_count": sessions,
    };
    events.record_outcome(
        events.MEMORY_COMMIT_SUCCEEDED,
        events.MEMORY_COMMIT_FAILED,
        host=spec.host,
        session_id_env=spec.session_id_env,
        success=success,
        latency_ms=latency_ms,
        **counts,
    );
    if not success or not _cycle_is_open(layout) {
        return;
    }
    duration_ms = _cycle_duration_ms(layout);
    if duration_ms is not None {
        counts["duration_ms"] = duration_ms;
    }
    events.record(
        events.MEMORY_UPDATE_SUCCEEDED,
        host=spec.host,
        session_id_env=spec.session_id_env,
        properties=counts,
    );
}

impl _cmd_verify_resources(spec: HostSpec, args: argparse.Namespace) -> int {
    layout = _layout(spec, args);
    kept = verify_resource_log(layout.resource_log, layout.resources);
    print(f"{kept} resource(s) written to {layout.resources}");
    return 0;
}

impl _smells_like_transport(exc: BaseException) -> bool {
    import from memu.env { ConfigError }
    seen: list[BaseException] = [];
    current: any = exc;
    while current is not None and current not in seen {
        seen.append(current);
        current = current.__cause__ or current.__context__;
    }
    if any((isinstance(e, ConfigError) for e in seen)) {
        return False;
    }
    for e in seen {
        text = f"{type(e).__name__} {e}".lower();
        if any((smell in text for smell in _TRANSPORT_SMELLS)) {
            return True;
        }
    }
    return False;
}

impl _proxy_hint(base_url: str) -> str | None {
    proxies = urllib.request.getproxies();
    if not proxies {
        return None;
    }
    import from memu.embedding.http_client { is_loopback_url }
    listing = ", ".join(sorted(set(proxies.values())));
    env_configured = any((k.lower().endswith("_proxy") for k in os.environ));
    source = "the shell environment"
        if env_configured
        else "the OS's system-wide settings (invisible to `env`)";
    if not is_loopback_url(base_url) {
        return f"hint: requests to this target go through a proxy ({listing}, from {source}). If the target is actually this machine reached through a non-loopback address (host.docker.internal, a LAN IP, a WSL/VM host address), the proxy cannot reach it — add that address to NO_PROXY.";
    }
    if os.environ.get("MEMU_HTTP_PROXY") {
        return "hint: the embedding target is this machine, and your explicit MEMU_HTTP_PROXY routes memU's traffic through a proxy anyway. If that proxy cannot reach your localhost, unset MEMU_HTTP_PROXY.";
    }
    return f"hint: the embedding target is this machine and a proxy is configured ({listing}, from {source}). This memU bypasses proxies for loopback targets, so the proxy is likely not the cause — check the embedding server itself (is it running? does `curl {base_url}` answer?). On older memU releases the proxy *would* hijack this call; there, set NO_PROXY=localhost,127.0.0.1.";
}

impl _cmd_doctor(spec: HostSpec, args: argparse.Namespace) -> int {
    backend_status = await _cmd_backend_doctor(spec, args);
    if spec.host in {"codex", "claude-code"} and (not getattr(args, "backend_only", False)) {
        if spec.host == "codex" {
            import from memu.hosts.codex.doctor { check }
        } else {
            import from memu.hosts.claude_code.doctor { check as check_claude }
            check = check_claude;
        }
        integration_status = check();
        return int(bool(backend_status or integration_status));
    }
    return backend_status;
}

impl _cmd_backend_doctor(spec: HostSpec, args: argparse.Namespace) -> int {
    import from memu.env { CONFIG_ENV, cloud_base_url, embedding_provider, env, memory_mode }
    try {
        mode = memory_mode();
        result = await retrieval.retrieve("smoke test");
    } except Exception as exc {
        if os.environ.get("MEMU_DEBUG") == "1" {
            raise;
        }
        print(f"error: {exc} (set MEMU_DEBUG=1 for a traceback)", file=sys.stderr);
        if _smells_like_transport(exc) {
            try {
                target = cloud_base_url()
                    if memory_mode() == "cloud"
                    else env("MEMU_BASE_URL", "") or "";
            } except Exception {
                target = "";
            }
            hint = _proxy_hint(target);
            if hint {
                print(hint, file=sys.stderr);
            }
        }
        return 1;
    }
    found = events.counts(result, layers=("hits", "resources"));
    print(f"config    {os.path.expanduser(CONFIG_ENV)}");
    print(f"mode      {mode}");
    if mode == "cloud" {
        print(f"endpoint  {cloud_base_url()}");
        print("resources accepted but not currently persisted by memU Cloud");
    } else {
        print(f"store     {env('MEMU_DB')}");
        print(f"provider  {embedding_provider()}");
    }
    print(f"retrieval ok ({found} hit(s) for a smoke-test query; 0 is fine on a new store)");
    return 0;
}

impl _cmd_docs(spec: HostSpec, args: argparse.Namespace) -> int {
    filename = DOCS[args.doc];
    embedded = (files(spec.package) / filename).read_text(encoding="utf-8");
    resolved = templates.resolve_doc(spec.host, filename, embedded);
    print(spec.render_doc(resolved));
    event = GUIDE_EVENTS.get(args.doc);
    if event {
        _report_guide_opened(spec, event);
    }
    return 0;
}

impl _report_guide_opened(spec: HostSpec, event: str) {
    events.record(event, host=spec.host, session_id_env=spec.session_id_env);
    events.flush();
}

impl _cmd_hook_run(spec: HostSpec, args: argparse.Namespace) -> int {
    if spec.host in {"codex", "claude-code", "pi", "hermes"} {
        if spec.host == "codex" {
            import from memu.hosts.codex.notify_console { memorize_run as codex_run }
            memorize_run = codex_run;
        } elif spec.host == "pi" {
            import from memu.hosts.pi.memorize_hook { memorize_run as pi_run }
            memorize_run = pi_run;
        } elif spec.host == "hermes" {
            import from memu.hosts.hermes.memorize_hook { memorize_run as hermes_run }
            memorize_run = hermes_run;
        } else {
            import from memu.hosts.claude_code.memorize_hook { memorize_run as claude_code_run }
            memorize_run = claude_code_run;
        }
        with memorize_run(_layout(spec, args)) as admitted {
            if not admitted {
                return 0;
            }
            code = 1;
            try {
                code = await _run_hook_pipeline(spec, args);
                return code;
            } finally {
                print(f"=== MEMORIZE status={'failed' if code else 'succeeded'} ===", flush=True);
            }
        }
    }
    return await _run_hook_pipeline(spec, args);
}

impl _run_hook_pipeline(spec: HostSpec, args: argparse.Namespace) -> int {
    hook = spec.hook;
    if hook is None {
        raise RuntimeError(f"{spec.display} has no notify hook");
    }
    layout = _layout(spec, args);
    code = await _cmd_prepare(spec, args);
    if code {
        return code;
    }
    if hooks.pending_jobs(layout) {
        if args.console and hook.stream_output is None {
            raise ValueError(f"{spec.display} has no live agent output");
        }
        hooks.run_agent(
            hook.agent, layout, executable=args.agent, stream_output=hook.stream_output
        );
    }
    return await _cmd_commit(spec, args);
}

impl _cmd_schedule(spec: HostSpec, args: argparse.Namespace) -> int {
    system = platform.system();
    if system != "Windows" {
        if spec.host == "hermes" and args.action in {"status", "uninstall"} {
            print(
                "Hermes legacy schedule inspection/removal is verified only on Windows. No cron, launchd or Hermes native cron tasks were inspected or removed.",
                file=sys.stderr,
            );
            return 1;
        }
        print(
            f"{spec.display} bridging on {system or 'this OS'} is scheduled with cron or launchd — follow that section of `{spec.binary} docs task`. The `schedule` helper automates Windows Task Scheduler only.",
        );
        return 0;
    }
    import memu.hosts.scheduling as scheduling;
    layout = _layout(spec, args);
    if args.action in {"status", "uninstall"} and spec.host == "hermes" {
        return scheduling.cleanup(spec, layout, remove=args.action == "uninstall");
    }
    if args.action == "install" {
        return scheduling.install(spec, layout, interval_minutes=args.interval);
    }
    if args.action == "uninstall" {
        return scheduling.uninstall(spec, layout);
    }
    if args.action == "status" {
        return scheduling.status(spec, layout);
    }
    return scheduling.verify(spec, layout);
}

impl _cmd_report(spec: HostSpec, args: argparse.Namespace) -> int {
    outcome = "recorded" if events.enabled() else "reporting is off; nothing recorded";
    if args.what == "install" {
        events.record(
            events.CLI_INSTALL_SUCCEEDED, host=spec.host, session_id_env=spec.session_id_env
        );
        events.flush();
        print(outcome);
        return 0;
    }
    if args.what == "uninstall" {
        events.record(
            events.CLI_UNINSTALL_SUCCEEDED, host=spec.host, session_id_env=spec.session_id_env
        );
        events.flush();
        print(outcome);
        return 0;
    }
    if args.what == "error" {
        events.record_agent_error(
            stage=args.stage, detail=args.detail, host=spec.host, session_id_env=spec.session_id_env
        );
        events.flush();
        print(outcome);
        return 0;
    }
    (accepted, rejected) = events.flush();
    print(f"delivered {accepted} event(s)");
    if rejected {
        print(f"{rejected} event(s) discarded — the server rejected them", file=sys.stderr);
    }
    return 0;
}

impl _register_report(sub: Any, handler: Any) {
    parser = sub.add_parser("report", help="Report a lifecycle event to memU");
    what = parser.add_subparsers(dest="what", required=True);
    installed = what.add_parser(
        "install", help="Record that installation completed successfully (delivers immediately)"
    );
    installed.set_defaults(handler=handler);
    uninstalled = what.add_parser(
        "uninstall", help="Record that memU was uninstalled (delivers immediately)"
    );
    uninstalled.set_defaults(handler=handler);
    failed = what.add_parser("error", help="Report a failure memU could not observe on its own");
    failed.add_argument(
        "--stage",
        required=True,
        choices=events.STAGES,
        help="Which operation failed. 'other' is the catchall — use it rather than not reporting",
    );
    failed.add_argument(
        "--detail",
        default="",
        help=f"What went wrong, in your own words and in detail — a human reads this to work out what is broken on the machine, so say what you ran, what happened instead, and what you think the cause is. Not a traceback: memU already reports the exception itself. Never credentials, absolute paths, memory content, or transcript text. Truncated at {events.MAX_DETAIL_CHARS} characters",
    );
    failed.set_defaults(handler=handler);
    flusher = what.add_parser("flush", help="Deliver any events still spooled on this machine");
    flusher.set_defaults(handler=handler);
}

impl build_parser(spec: HostSpec) -> argparse.ArgumentParser {
    parser = argparse.ArgumentParser(
        prog=spec.binary,
        description=f"memU's {spec.display} host adapter — the scheduled bridging task and its install guide.",
    );
    sub = parser.add_subparsers(dest="command", required=True);
    def with_base(p: argparse.ArgumentParser) -> argparse.ArgumentParser {
        p.add_argument(
            "--base-dir",
            default=spec.default_base_dir,
            help=f"memU working directory (default: {spec.default_base_dir})",
        );
        return p;
    }
    def bind(handler: Callable[[HostSpec, argparse.Namespace], Coroutine[Any, Any, int]]) -> Any {
        return functools.partial(handler, spec);
    }
    retrieval.register(sub, host=spec.host, session_id_env=spec.session_id_env);
    _register_report(sub, bind(_cmd_report));
    config_cmd.register(
        sub, binary=spec.binary, host=spec.host, session_id_env=spec.session_id_env
    );
    instruction.register(
        sub,
        path=spec.instruction_path,
        binary=spec.binary,
        skills_dir=spec.skills_dir,
        legacy_paths=spec.legacy_instruction_paths,
    );
    p = with_base(
        sub.add_parser(
            "prepare", help=f"Slice new {spec.display} sessions into self-evolve job files"
        ),
    );
    p.add_argument(
        "--session-dir",
        default=spec.session_dir or None,
        required=not spec.session_dir,
        help=f"{spec.session_help}"
            + (f" (default: {spec.session_dir})" if spec.session_dir else ""),
    );
    p.add_argument(
        "--max-jobs", type=int, default=MAX_JOBS, help=f"Sessions per run (default: {MAX_JOBS})"
    );
    p.set_defaults(handler=bind(_cmd_prepare));
    p = with_base(
        sub.add_parser("commit", help="Submit what the self-evolve jobs produced back into memU")
    );
    p.set_defaults(handler=bind(_cmd_commit));
    p = with_base(
        sub.add_parser(
            "verify-resources",
            help="Filter the touched-file log into the describe-me resource file",
        ),
    );
    p.set_defaults(handler=bind(_cmd_verify_resources));
    p = sub.add_parser(
        "doctor",
        help=f"Check backend, standalone {spec.display} CLI and local hook definitions"
            if spec.host in {"codex", "claude-code"}
            else "Verify MEMU_* config resolves and the selected memory backend is reachable",
    );
    if spec.host in {"codex", "claude-code", "pi", "hermes"} {
        p.add_argument(
            "--backend-only",
            action="store_true",
            help="Check only the memory backend (installer preflight)",
        );
    }
    p.set_defaults(handler=bind(_cmd_doctor));
    p = sub.add_parser("docs", help="Print a packaged agent-facing guide");
    p.add_argument(
        "doc",
        choices=sorted(DOCS),
        help="install: the setup guide; task: the bridging-task procedure; uninstall: the removal guide",
    );
    p.set_defaults(handler=bind(_cmd_docs));
    if spec.schedule_command {
        p = with_base(
            sub.add_parser(
                "schedule",
                help=f"Register the {spec.display} bridging task (Windows Task Scheduler)",
            ),
        );
        p.add_argument(
            "action",
            choices=("install", "uninstall", "status", "verify"),
            help="install/uninstall the task, show its status, or verify it can run",
        );
        p.add_argument(
            "--interval",
            type=int,
            default=60,
            help="Minutes between runs, for install (default: 60)",
        );
        p.set_defaults(handler=bind(_cmd_schedule));
    }
    if spec.register_extra is not None {
        spec.register_extra(sub);
    }
    if spec.hook is not None {
        hook = spec.hook;
        p = with_base(sub.add_parser("hook-run", help="Run one background memorization pass"));
        p.add_argument("--session-dir", default=spec.session_dir, help=spec.session_help);
        p.add_argument("--max-jobs", type=int, default=MAX_JOBS);
        p.add_argument("--agent", default="", help=f"Path to {hook.agent.argv[0]}");
        p.add_argument(
            "--console",
            action="store_true",
            help="Tee agent output to the run log and the foreground terminal",
        );
        p.set_defaults(handler=bind(_cmd_hook_run));
    }
    return parser;
}

impl run(spec: HostSpec, argv: list[str] | None = None) -> int {
    reconfigure_input = getattr(sys.stdin, "reconfigure", None);
    if reconfigure_input is not None {
        reconfigure_input(encoding="utf-8", errors="strict");
    }
    for stream in (sys.stdout, sys.stderr) {
        reconfigure = getattr(stream, "reconfigure", None);
        if reconfigure is not None {
            reconfigure(encoding="utf-8", errors="replace");
        }
    }
    args = build_parser(spec).parse_args(argv);
    handler: Callable[[argparse.Namespace], Coroutine[Any, Any, int]] = args.handler;
    try {
        return asyncio.run(handler(args));
    } except KeyboardInterrupt {
        return 130;
    } except Exception as exc {
        command = getattr(args, "command", "");
        events.record_cli_error(
            exc, command=command, host=spec.host, session_id_env=spec.session_id_env
        );
        if command != "retrieve" {
            try {
                events.flush();
            } except KeyboardInterrupt {
                return 130;
            }
        }
        if os.environ.get("MEMU_DEBUG") == "1" {
            raise;
        }
        print(f"error: {exc} (set MEMU_DEBUG=1 for a traceback)", file=sys.stderr);
        return 1;
    }
}
