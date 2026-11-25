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
    ) {
        require_sqlalchemy();
        self.dsn = dsn;
        self.ddl_mode = ddl_mode;
        self.vector_provider = vector_provider;
        self._use_vector_type = vector_provider == "pgvector";
        self._scope_model = scope_model or base_model or BaseModel;
        self._scope_fields = list(getattr(self._scope_model, "model_fields", {}).keys());
        self._state = DatabaseState();
        self._sessions = SessionManager(dsn=self.dsn);
        self._sqla_models = sqla_models or get_sqlalchemy_models(scope_model=self._scope_model);
        run_migrations(dsn=self.dsn, scope_model=self._scope_model, ddl_mode=self.ddl_mode);
        resource_model = resource_model or self._sqla_models.Resource;
        recall_file_model = recall_file_model or self._sqla_models.RecallFile;
        recall_file_segment_model = recall_file_segment_model
            or self._sqla_models.RecallFileSegment;
        self.resource_repo = PostgresResourceRepo(
            state=self._state,
            resource_model=resource_model,
            sqla_models=self._sqla_models,
            sessions=self._sessions,
            scope_fields=self._scope_fields,
        );
        self.recall_file_repo = PostgresRecallFileRepo(
            state=self._state,
            recall_file_model=recall_file_model,
            sqla_models=self._sqla_models,
            sessions=self._sessions,
            scope_fields=self._scope_fields,
        );
        self.recall_file_segment_repo = PostgresRecallFileSegmentRepo(
            state=self._state,
            recall_file_segment_model=recall_file_segment_model,
            sqla_models=self._sqla_models,
            sessions=self._sessions,
            scope_fields=self._scope_fields,
            use_vector=self._use_vector_type,
        );
        self.resources = self._state.resources;
        self.recall_files = self._state.recall_files;
        self.segments = self._state.segments;
    }

    def close {
        self._sessions.close();
    }

    def _load_existing {
        self.resource_repo.load_existing();
        self.recall_file_repo.load_existing();
        self.recall_file_segment_repo.load_existing();
    }
}
