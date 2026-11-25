import copy;
import from collections.abc { Iterator }
import from contextlib { contextmanager }
import from contextvars { ContextVar }
import from typing { Any }
import from sqlalchemy { text }
import from sqlmodel { Session }

class _BorrowedSession {
    has _session: Session;
    def init(session: Session);
    def __enter__ -> _BorrowedSession;
    def __exit__(*args: Any);
    def commit;
    def __getattr__(name: str) -> Any;
}

class AtomicSessionManager {
    has _active: ContextVar[Session | None],
        _engine: Any;
    def init(*, engine: Any);
    def session -> Session | _BorrowedSession;
    @contextmanager
    def atomic -> Iterator[None];
    @contextmanager
    def snapshot -> Iterator[None];
}

@contextmanager
def preserve_state(state: DatabaseState) -> Iterator[None];
