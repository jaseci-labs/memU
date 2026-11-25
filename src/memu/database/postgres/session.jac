import builtins;

import logging;

import from typing { Any, Optional }

glob msg: any,
     Session: any,
     create_engine: any,
     logger: any,
     __all__: any;

with entry {
    try {
        import from sqlmodel { Session, create_engine }
    } except ImportError as exc {
        raise ImportError("sqlmodel is required for Postgres storage support") from exc;
    }

    logger = logging.getLogger(__name__);
}

obj SessionManager {
    has _engine: any;

    def init(*, dsn: str, engine_kwargs: Optional[dict[str, Any]] = None) {
        kw: any = {"pool_pre_ping": True};
        if engine_kwargs {
            kw.update(engine_kwargs);
        }
        self._engine = create_engine(dsn, **kw);
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

    def __repr__ -> str {
        return (getattr(builtins.object, "__repr__") as any)(self);
    }

    def __eq__(other: any) -> bool {
        return self is other;
    }

    def __hash__ -> int {
        return id(self);
    }
}

with entry {
    __all__ = ["SessionManager"];
}
