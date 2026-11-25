import os;

import from dataclasses { dataclass }

import from pathlib { Path }

glob BASE_DIR: any = "~/.memu";

glob TRACK_DIRS: dict[str, str];

with entry {
    TRACK_DIRS = {"memory": "memory", "skill": "skill"};
    base_default_ = BASE_DIR;
}

glob base_default_: any;

@dataclass(frozen=True)
class Layout {
    has base: Path;

    has host: str;

    class def `default(host: str, base: str | Path = base_default_) -> Layout;

    has sessions: Path {
        getter {
            return self.base / "sessions";
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

    has session_manifest: Path {
        getter {
            return self.base / f".session_manifest.{self.host}.json";
        }
    }

    has session_manifest_pending: Path {
        getter {
            return self.session_manifest.with_name(self.session_manifest.name + ".pending");
        }
    }

    has run_marker: Path {
        getter {
            return self.base / f".bridging_run.{self.host}.json";
        }
    }

    has self_sessions: Path {
        getter {
            return self.base / f".self_sessions.{self.host}.json";
        }
    }

    has memory_manifest: Path {
        getter {
            return self.base / ".memory_manifest.json";
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
            return `list(TRACK_DIRS.values());
        }
    }
}
