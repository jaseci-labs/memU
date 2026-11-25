import logging;
import from typing { Any, Optional }
import from sqlmodel { Session, create_engine }

glob logger = logging.getLogger(__name__);

class SessionManager {
    has _engine: any;

    def init(*, dsn: str, engine_kwargs: Optional[dict[str, Any]] = None) {
        self._engine = create_engine(dsn, **{"pool_pre_ping": True, **(engine_kwargs or {})});
    }

    def session -> Session {
        return Session(self._engine, expire_on_commit=False);
    }

    def close {
        try {
            self._engine.dispose();
        } except Exception {
            logger.exception("Failed to close Postgres engine");
        }
    }
}
