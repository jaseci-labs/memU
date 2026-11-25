import importlib;
import sys;
import from dataclasses { replace }
import from typing { Any, Optional }
glob HOST = "hermes",
     SESSION_ID_ENV = "HERMES_SESSION_ID",
     SOUL_MD = str(hermes_home() / "SOUL.md");

def _register_extra(sub: Any) {
    sub.choices["install-instruction"].description = "Install on-demand memU retrieval inline in SOUL.md";
    sub.choices["remove-instruction"].set_defaults(skills_dir=str(hermes_home() / "skills"));
    memorize_hook = importlib.import_module("memu.hosts.hermes.memorize_hook");
    memorize_hook.register(sub);
    install.register(sub);
    hook_install.register(sub);
}

glob SPEC: any;

with entry {
    SPEC = HostSpec(
        host=HOST,
        display="Hermes",
        package="memu.hosts.hermes",
        task_name="memu-bridging-hermes",
        source_factory=HermesTranscriptSource,
        session_dir=str(state_db_path()),
        session_help="Hermes SQLite session store (state.db under HERMES_HOME)",
        instruction_path=SOUL_MD,
        schedule_backend="os",
        schedule_command="hermes -z {prompt}",
        schedule_prepare_session_dir=True,
        session_id_env=SESSION_ID_ENV,
        hook=hooks.HookSpec(
            agent=hooks.HeadlessAgent(argv=("hermes", "chat", "--ignore-rules")),
            stream_output=hook.stream_agent,
        ),
        register_extra=_register_extra,
    );
}

def main(argv: Optional[list[str]] = None) -> int {
    spec = replace(
        SPEC, instruction_path=str(hermes_home() / "SOUL.md"), session_dir=str(state_db_path())
    );
    return run(spec, argv);
}

with entry:__main__ {
    sys.exit(main());
}
