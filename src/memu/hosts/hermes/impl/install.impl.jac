impl _command(argv: list[str]) -> int {
    import from memu.hosts.hermes.cli { SPEC }
    import from memu.hosts.host_cli { build_parser }
    spec = replace(
        SPEC, instruction_path=str(hermes_home() / "SOUL.md"), session_dir=str(state_db_path())
    );
    args = build_parser(spec).parse_args(argv);
    return int(await args.handler(args));
}

impl _stage(stage: int, args: argparse.Namespace) {
    if stage == 1 {
        executable = shutil.which("hermes");
        if not executable {
            raise lifecycle.Blocked(
                "Hermes was not found on PATH; open a terminal where hermes is available."
            );
        }
        hook_install.target();
        instruction.check_skill_cleanup(hermes_home() / "skills", "memu-hermes");
        print(f"   Hermes: {executable}");
    } elif stage == 2 {
        await lifecycle.backend(args, _command);
    } else {
        lock = hook_install.home() / ".memu-hooks-lock";
        lock.mkdir(parents=True, exist_ok=True);
        with workspace_lock(lock) as acquired {
            if not acquired {
                raise lifecycle.Blocked(
                    "Another Hermes installation update is running; retry later."
                );
            }
            hook_install.configure_memorize(Path(args.base_dir));
            if platform.system() == "Windows"
                and await _command(["schedule", "uninstall", "--base-dir", str(args.base_dir)])
            {
                raise lifecycle.Blocked(
                    "Legacy Windows schedule cleanup failed; SOUL.md was not changed."
                );
            }
            hook_install.remove_legacy_plugin();
            if await _command(["install-instruction"]) {
                raise lifecycle.Failed("SOUL.md instruction installation failed.");
            }
            path = hermes_home() / "SOUL.md";
            if instruction.block("memu-hermes") not in path.read_text(encoding="utf-8") {
                raise lifecycle.Failed("SOUL.md readback verification failed.");
            }
        }
    }
}

impl run(args: argparse.Namespace) -> int {
    return await lifecycle.run(
        args,
        host="hermes",
        stages=STAGES,
        execute=_stage,
        welcome="\nWelcome to memU · Hermes",
        completion={
            "instruction_verification": "soul_managed_block_readback",
            "memorize_hook": "on_session_end_shell_hook",
            "instruction_path": str(hermes_home() / "SOUL.md"),
            "restart_required": True,
            "notice": "Start a fresh Hermes session to load SOUL.md. Restart running Hermes processes after legacy plugin removal. Non-Windows and Hermes native cron schedules require separate cleanup.",
        },
    );
}

impl register(sub: Any) {
    parser = sub.add_parser(
        "install", help="Configure the backend and on-demand retrieval in SOUL.md"
    );
    lifecycle.add_arguments(parser, "hermes", install_missing=False);
    parser.set_defaults(handler=run);
}
