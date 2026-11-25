import from typing { Type }
import logging;
import from typing { Any }
import from pydantic { BaseModel }
glob logger = logging.getLogger(__name__);

class PostgresStore(Database) {
    has _sqla_models: SQLAModels,
        _sessions: any,
        _state: any,
        _scope_fields: any,
        _scope_model: Type[BaseModel],
        _use_vector_type: any,
        vector_provider: str | None,
        ddl_mode: DDLMode,
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
        ddl_mode: DDLMode = "create",
        vector_provider: str | None = None,
        scope_model: Type[BaseModel] | None = None,
        base_model: Type[BaseModel] | None = None,
        resource_model: Type[Any] | None = None,
        recall_file_model: Type[Any] | None = None,
        recall_file_segment_model: Type[Any] | None = None,
        sqla_models: SQLAModels | None = None,
    );
    def close;
    def _load_existing;
}
