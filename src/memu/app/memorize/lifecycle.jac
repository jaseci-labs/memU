import builtins;
import json;
import from dataclasses { dataclass }
import from pathlib { Path }
import from typing { Any }

@dataclass(frozen=True)
class MemorizeWorkspace {
    has base: Path;

    has input: Path {
        getter {
            return self.base / "input";
        }
    }

    has jobs: Path {
        getter {
            return self.base / "jobs";
        }
    }

    has memory: Path {
        getter {
            return self.base / TRACK_DIRS["memory"];
        }
    }

    has skill: Path {
        getter {
            return self.base / TRACK_DIRS["skill"];
        }
    }

    has manifest: Path {
        getter {
            return self.base / ".memorize_manifest.json";
        }
    }

    has active_run: Path {
        getter {
            return self.base / ".memorize_run.json";
        }
    }

    has resource_log: Path {
        getter {
            return self.base / ".resource.tmp";
        }
    }

    has resources: Path {
        getter {
            return self.base / "resources.md";
        }
    }

    has track_dirs: list[str] {
        getter {
            return list(TRACK_DIRS.values());
        }
    }
}

@dataclass(frozen=True, init=False)
class PreparedMemorizeRun {
    has transcripts: list[MaterializedConversation],
        jobs: list[Path];
    def init(
        transcript: MaterializedConversation | list[MaterializedConversation], jobs: list[Path]
    );

    has transcript: MaterializedConversation {
        getter {
            return self.transcripts[0];
        }
    }
}

def _numeric_path_key(path: Path) -> int;
async def _mirror_recall_files(backend: any, workspace: MemorizeWorkspace);
async def prepare_memorize(
    memorize_input: list[MemorizeInput] | MemorizeInput,
    workspace: MemorizeWorkspace,
    backend: any,
    *,
    verify_command: str,
) -> PreparedMemorizeRun;
async def commit_memorize(workspace: MemorizeWorkspace, backend: any) -> dict[str, Any];
