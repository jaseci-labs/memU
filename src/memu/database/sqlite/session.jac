import logging;
import from collections.abc { Iterator }
import from contextlib { contextmanager }
import from typing { Any }
import from sqlalchemy.exc { SQLAlchemyError }
import from sqlmodel { create_engine }
glob logger = logging.getLogger(__name__);

class SQLiteSessionManager {
    has _atomic_manager: any,
        _engine: any;
    def init(*, dsn: str, engine_kwargs: dict[str, Any] | None = None);
    def session -> Any;
    @contextmanager
    def atomic -> Iterator[None];
    @contextmanager
    def snapshot -> Iterator[None];
    def close;

    has engine: Any {
        getter {
            return self._engine;
        }
    }
}

glob __all__ = ["SQLiteSessionManager"];
