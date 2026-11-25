import from dataclasses { dataclass, field }
import from threading { RLock }

@dataclass
class DatabaseState {
    has lock: RLock = field(default_factory=RLock, repr=False),
        resources: dict[str, Resource] = field(default_factory=dict[any, any]),
        recall_files: dict[str, RecallFile] = field(default_factory=dict[any, any]),
        segments: list[RecallFileSegment] = field(default_factory=list[any]);
}

glob __all__ = ["DatabaseState"];
