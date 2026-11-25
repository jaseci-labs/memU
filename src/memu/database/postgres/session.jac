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

    def init(*, dsn: str, engine_kwargs: Optional[dict[str, Any]] = None);

    def session -> Session;

    def close;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}

with entry {
    __all__ = ["SessionManager"];
}
