impl _register_extra(sub: object) {
    install.register(sub);
    uninstall.register(sub);
    cli_prepare.register(sub);
    prompt_hook.register(sub);
    memorize_hook.register(sub);
    prompt_hook_install.register(sub);
}

impl build_parser -> argparse.ArgumentParser {
    _build = importlib.import_module("memu.hosts.host_cli").build_parser;
    return _build(SPEC);
}

impl main(argv: Optional[list[str]] = None) -> int {
    return run(SPEC, argv);
}
