impl _BorrowedSession.init(session: Session) {
    self._session = session;
}

impl _BorrowedSession.__enter__ -> _BorrowedSession {
    return self;
}

impl _BorrowedSession.__exit__(*args: Any) {
    return None;
}

impl _BorrowedSession.commit {
    self._session.flush();
}

impl _BorrowedSession.__getattr__(name: str) -> Any {
    return getattr(self._session, name);
}

impl AtomicSessionManager.init(*, engine: Any) {
    self._engine = engine;
    self._active = ContextVar(f"memu_transaction_{id(self)}", default=None);
}

impl AtomicSessionManager.session -> Session | _BorrowedSession {
    active = self._active.get();
    return _BorrowedSession(active)
        if active is not None
        else Session(self._engine, expire_on_commit=False);
}

impl AtomicSessionManager.atomic -> Iterator[None] {
    if self._active.get() is not None {
        msg = "Nested memU write transactions are not supported";
        raise RuntimeError(msg);
    }
    with Session(self._engine, expire_on_commit=False) as session {
        session.execute(text("BEGIN IMMEDIATE"));
        token = self._active.set(session);
        try {
            yield None;
            session.commit();
        } except BaseException {
            session.rollback();
            raise;
        } finally {
            self._active.reset(token);
        }
    }
}

impl AtomicSessionManager.snapshot -> Iterator[None] {
    if self._active.get() is not None {
        msg = "Nested memU read transactions are not supported";
        raise RuntimeError(msg);
    }
    with Session(self._engine, expire_on_commit=False) as session {
        session.execute(text("BEGIN"));
        token = self._active.set(session);
        try {
            yield None;
        } finally {
            self._active.reset(token);
            session.rollback();
        }
    }
}

impl preserve_state(state: DatabaseState) -> Iterator[None] {
    with state.lock {
        resources: any = copy.deepcopy(state.resources);
        recall_files: any = copy.deepcopy(state.recall_files);
        segments = copy.deepcopy(state.segments);
        try {
            yield None;
        } except BaseException {
            state.resources.clear();
            (state.resources as any).update(resources);
            state.recall_files.clear();
            (state.recall_files as any).update(recall_files);
            state.segments[:] = segments;
            raise;
        }
    }
}
