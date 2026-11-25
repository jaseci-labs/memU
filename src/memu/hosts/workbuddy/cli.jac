import from typing { Optional }
import sys;
glob HOST = "workbuddy",
     SOUL_MD = "~/.workbuddy/SOUL.md",
     MEMORY_MD = "~/.workbuddy/MEMORY.md",
     SPEC = HostSpec(
         host=HOST,
         display="WorkBuddy",
         package="memu.hosts.workbuddy",
         task_name="memu-bridging-workbuddy",
         source_factory=WorkBuddyTranscriptSource,
         session_dir=SESSION_DIR,
         session_help="WorkBuddy session log (one project dir per escaped cwd)",
         instruction_path=SOUL_MD,
         legacy_instruction_paths=(MEMORY_MD,),
         schedule_backend="native",
     );

def main(argv: Optional[list[str]] = None) -> int {
    return run(SPEC, argv);
}

with entry:__main__ {
    sys.exit(main());
}
