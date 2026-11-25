impl _cmd_legacy_schedule(args: argparse.Namespace) -> int {
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

impl _register_extra(sub: Any) {
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

impl main(argv: Optional[list[str]] = None) -> int {
    return run(SPEC, argv);
}
