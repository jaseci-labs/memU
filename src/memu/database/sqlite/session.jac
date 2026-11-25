import logging;
import from collections.abc { Iterator }
import from contextlib { contextmanager }
import from typing { Any, Optional }
import from sqlalchemy.exc { SQLAlchemyError }
import from sqlmodel { create_engine }
glob logger = logging.getLogger(__name__);

class SQLiteSessionManager {
    has _atomic_manager: any,
        _engine: any;

    def init(*, dsn: str, engine_kwargs: Optional[dict[str, Any]] = None) {
        kw: dict[str, Any] = {"connect_args": {"check_same_thread": False}};
        if engine_kwargs {
            kw.update(dict(engine_kwargs));
        }
        self._engine = create_engine(dsn, **kw);
        self._atomic_manager = AtomicSessionManager(engine=self._engine);
    }

    def session -> Any {
        return self._atomic_manager.session();
    }

    @contextmanager
    def atomic -> Iterator[None] {
        with self._atomic_manager.atomic() {
            yield None;
        }
    }

    @contextmanager
    def snapshot -> Iterator[None] {
        with self._atomic_manager.snapshot() {
            yield None;
        }
    }

    def close {
        try {
            self._engine.dispose();
        } except SQLAlchemyError {
            logger.exception("Failed to close SQLite engine");
        }
    }

    has engine: Any {
        getter {
            return self._engine;
        }
    }
}

glob __all__ = ["SQLiteSessionManager"];
