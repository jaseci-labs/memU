impl _register_extra(sub: object) {
    install.register(sub);
    uninstall.register(sub);
    cli_prepare.register(sub);
    prompt_hook.register(sub);
    memorize_hook.register(sub);
    prompt_hook_install.register(sub);
}

impl build_parser -> argparse.ArgumentParser {
    import from memu.hosts.host_cli { build_parser as _build }
    return _build(SPEC);
}

impl main(argv: list[str] | None = None) -> int {
    return run(SPEC, argv);
}
