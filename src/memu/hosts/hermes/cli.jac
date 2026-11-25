import importlib;
import sys;
import from dataclasses { replace }
import from typing { Any, Optional }
glob HOST = "hermes",
     SESSION_ID_ENV = "HERMES_SESSION_ID",
     SOUL_MD = str(hermes_home() / "SOUL.md");

with entry {}

def _register_extra(sub: Any);
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

def main(argv: Optional[list[str]] = None) -> int;

with entry:__main__ {
    sys.exit(main());
}
