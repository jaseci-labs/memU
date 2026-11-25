import from typing { Type }
import logging;
import from collections.abc { Iterator }
import from contextlib { contextmanager }
import from typing { Any }
import from pydantic { BaseModel }
import from sqlmodel { SQLModel }
glob logger = logging.getLogger(__name__);

class SQLiteStore(Database) {
    has _sqla_models: SQLiteSQLAModels,
        _sessions: any,
        _state: any,
        _scope_fields: any,
        _scope_model: Type[BaseModel],
        dsn: str,
        resource_repo: ResourceRepo,
        recall_file_repo: RecallFileRepo,
        recall_file_segment_repo: RecallFileSegmentRepo,
        resources: dict[str, Resource],
        recall_files: dict[str, RecallFile],
        segments: list[RecallFileSegment];
    def init(
        *,
        dsn: str,
        scope_model: Type[BaseModel] | None = None,
        resource_model: Type[Any] | None = None,
        recall_file_model: Type[Any] | None = None,
        recall_file_segment_model: Type[Any] | None = None,
        sqla_models: SQLiteSQLAModels | None = None,
    );
    def _create_tables;
    @contextmanager
    def atomic -> Iterator[None];
    @contextmanager
    def snapshot -> Iterator[None];
    def close;
    def load_existing;
}

glob __all__ = ["SQLiteStore"];
