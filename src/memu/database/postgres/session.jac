import builtins;

import logging;

import from typing { Any }

glob msg: any;

glob Session: any;

glob create_engine: any;

glob logger: any;

glob __all__: any;

with entry {
    try {
        import from sqlmodel { Session, create_engine }
    } except ImportError as exc {
        msg = "sqlmodel is required for Postgres storage support";
        raise ImportError(msg) from exc;
    }

    logger = logging.getLogger(__name__);
}

obj SessionManager {
    has _engine: any;

    def init(*, dsn: str, engine_kwargs: dict[str, Any] | None = None);

    def session -> Session;

    def close;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}

with entry {
    __all__ = ["SessionManager"];
}
