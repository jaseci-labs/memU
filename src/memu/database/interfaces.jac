import from contextlib { AbstractContextManager }
import from typing { Protocol, runtime_checkable }

@runtime_checkable
class Database(Protocol) {
    has resource_repo: ResourceRepo,
        recall_file_repo: RecallFileRepo,
        recall_file_segment_repo: RecallFileSegmentRepo,
        resources: dict[str, ResourceRecord],
        recall_files: dict[str, RecallFileRecord],
        segments: list[RecallFileSegmentRecord];
    def close abst;
}

@runtime_checkable
class AtomicDatabase(Database, Protocol) {
    def atomic -> AbstractContextManager[None] abst;
    def snapshot -> AbstractContextManager[None] abst;
}

glob __all__ = [
    "AtomicDatabase",
    "Database",
    "RecallFileRecord",
    "RecallFileSegmentRecord",
    "ResourceRecord",
];
