impl SQLiteSessionManager.init(*, dsn: str, engine_kwargs: Optional[dict[str, Any]] = None) {
    kw: dict[str, Any] = {"connect_args": {"check_same_thread": False}};
    if engine_kwargs {
        kw.update(dict(engine_kwargs));
    }
    self._engine = create_engine(dsn, **kw);
    self._atomic_manager = AtomicSessionManager(engine=self._engine);
}

impl SQLiteSessionManager.session -> Any {
    return self._atomic_manager.session();
}

impl SQLiteSessionManager.atomic -> Iterator[None] {
    with self._atomic_manager.atomic() {
        yield None;
    }
}

impl SQLiteSessionManager.snapshot -> Iterator[None] {
    with self._atomic_manager.snapshot() {
        yield None;
    }
}

impl SQLiteSessionManager.close {
    try {
        self._engine.dispose();
    } except SQLAlchemyError {
        logger.exception("Failed to close SQLite engine");
    }
}
