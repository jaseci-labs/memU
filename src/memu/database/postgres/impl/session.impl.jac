impl SessionManager.init(*, dsn: str, engine_kwargs: dict[str, Any] | None = None) {
    kw: any = {"pool_pre_ping": True};
    if engine_kwargs {
        kw.update(engine_kwargs);
    }
    self._engine = create_engine(dsn, **kw);
}

impl SessionManager.session -> Session {
    return Session(self._engine, expire_on_commit=False);
}

impl SessionManager.close -> None {
    try {
        self._engine.dispose();
    } except Exception {
        logger.exception("Failed to close Postgres engine");
    }
}

impl SessionManager.__repr__ -> str {
    return (getattr(builtins.object, "__repr__") as any)(self);
}

impl SessionManager.__eq__(other: any) -> bool {
    return self is other;
}

impl SessionManager.__hash__ -> int {
    return id(self);
}
