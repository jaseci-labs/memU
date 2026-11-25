impl _cmd_register_cron_job(args: argparse.Namespace) -> int {
    registration = cron_identity.save_registration(
        cron_identity.registration_path(args.base_dir), job_id=args.job_id
    );
    print(f"registered OpenClaw cron job {registration.job_id}");
    return 0;
}

impl _register_cron_job(sub: Any) {
    parser = sub.add_parser(
        "register-cron-job",
        help="Record the exact OpenClaw cron job whose sessions prepare must skip",
    );
    parser.add_argument(
        "--job-id", required=True, help="OpenClaw cron job id returned at creation"
    );
    parser.add_argument("--base-dir", default="~/.memu/hosts/openclaw", help=argparse.SUPPRESS);
    parser.set_defaults(handler=_cmd_register_cron_job);
}

impl main(argv: list[str] | None = None) -> int {
    return run(SPEC, argv);
}
