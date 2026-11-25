impl _register_extra(sub: Any) {
    sub.choices["install-instruction"].description = "Install on-demand memU retrieval inline in SOUL.md";
    sub.choices["remove-instruction"].set_defaults(skills_dir=str(hermes_home() / "skills"));
    memorize_hook = importlib.import_module("memu.hosts.hermes.memorize_hook");
    memorize_hook.register(sub);
    install.register(sub);
    hook_install.register(sub);
}

impl main(argv: Optional[list[str]] = None) -> int {
    spec = replace(
        SPEC, instruction_path=str(hermes_home() / "SOUL.md"), session_dir=str(state_db_path())
    );
    return run(spec, argv);
}
