import copy;
import from collections.abc { Iterator }
import from contextlib { contextmanager }
import from contextvars { ContextVar }
import from typing { Any }
import from sqlalchemy { text }
import from sqlmodel { Session }

class _BorrowedSession {
    has _session: Session;

    def init(session: Session) {
        self._session = session;
    }

    def __enter__ -> _BorrowedSession {
        return self;
    }

    def __exit__(*args: Any) {
        return None;
    }

    def commit {
        self._session.flush();
    }

    def __getattr__(name: str) -> Any {
        return getattr(self._session, name);
    }
}

class AtomicSessionManager {
    has _active: ContextVar[Session | None],
        _engine: Any;

    def init(*, engine: Any) {
        self._engine = engine;
        self._active = ContextVar(f"memu_transaction_{id(self)}", default=None);
    }

    def session -> Session | _BorrowedSession {
        active = self._active.get();
        return _BorrowedSession(active)
            if active is not None
            else Session(self._engine, expire_on_commit=False);
    }

    @contextmanager
    def atomic -> Iterator[None] {
        if self._active.get() is not None {
            raise RuntimeError("Nested memU write transactions are not supported");
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

    @contextmanager
    def snapshot -> Iterator[None] {
        if self._active.get() is not None {
            raise RuntimeError("Nested memU read transactions are not supported");
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
}

@contextmanager
def preserve_state(state: DatabaseState) -> Iterator[None] {
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
