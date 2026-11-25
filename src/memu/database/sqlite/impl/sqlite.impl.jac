impl SQLiteStore.init(
    *,
    dsn: str,
    scope_model: Type[BaseModel] | None = None,
    resource_model: Type[Any] | None = None,
    recall_file_model: Type[Any] | None = None,
    recall_file_segment_model: Type[Any] | None = None,
    sqla_models: SQLiteSQLAModels | None = None,
) {
    self.dsn = dsn;
    self._scope_model = scope_model or BaseModel;
    self._scope_fields = list(getattr(self._scope_model, "model_fields", {}).keys());
    self._state = DatabaseState();
    self._sessions = SQLiteSessionManager(dsn=self.dsn);
    self._sqla_models = sqla_models or get_sqlite_sqlalchemy_models(scope_model=self._scope_model);
    self._create_tables();
    resource_model = resource_model or self._sqla_models.Resource;
    recall_file_model = recall_file_model or self._sqla_models.RecallFile;
    recall_file_segment_model = recall_file_segment_model or self._sqla_models.RecallFileSegment;
    (resource_record, file_record, segment_record) = build_scoped_models(self._scope_model);
    self.resource_repo = SQLiteResourceRepo(
        state=self._state,
        resource_model=resource_model,
        record_model=resource_record,
        sqla_models=self._sqla_models,
        sessions=self._sessions,
        scope_fields=self._scope_fields,
    );
    self.recall_file_repo = SQLiteRecallFileRepo(
        state=self._state,
        recall_file_model=recall_file_model,
        record_model=file_record,
        sqla_models=self._sqla_models,
        sessions=self._sessions,
        scope_fields=self._scope_fields,
    );
    self.recall_file_segment_repo = SQLiteRecallFileSegmentRepo(
        state=self._state,
        recall_file_segment_model=recall_file_segment_model,
        record_model=segment_record,
        sqla_models=self._sqla_models,
        sessions=self._sessions,
        scope_fields=self._scope_fields,
    );
    self.resources = self._state.resources;
    self.recall_files = self._state.recall_files;
    self.segments = self._state.segments;
}

impl SQLiteStore._create_tables {
    SQLModel.metadata.create_all(self._sessions.engine);
    self._sqla_models.Base.metadata.create_all(self._sessions.engine);
    logger.debug("SQLite tables created/verified");
}

impl SQLiteStore.atomic -> Iterator[None] {
    with preserve_state(self._state), self._sessions.atomic() {
        yield None;
    }
}

impl SQLiteStore.snapshot -> Iterator[None] {
    with self._state.lock, self._sessions.snapshot() {
        yield None;
    }
}

impl SQLiteStore.close {
    self._sessions.close();
}

impl SQLiteStore.load_existing {
    self.resource_repo.load_existing();
    self.recall_file_repo.load_existing();
    self.recall_file_segment_repo.load_existing();
}
