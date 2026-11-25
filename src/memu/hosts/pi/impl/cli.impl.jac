impl _register_extra(sub: Any) {
    install.register(sub);
    hook_install.register(sub);
}

impl main(argv: Optional[list[str]] = None) -> int {
    return run(SPEC, argv);
}
