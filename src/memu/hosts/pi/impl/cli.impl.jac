impl _register_extra(sub: Any) {
    install.register(sub);
    hook_install.register(sub);
}

impl main(argv: list[str] | None = None) -> int {
    return run(SPEC, argv);
}
