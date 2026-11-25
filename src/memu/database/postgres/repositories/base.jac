import logging;
import from typing { Any, Optional }
glob logger = logging.getLogger(__name__);

class PostgresRepoBase(SQLRepoBase) {
    has _use_vector: bool;
    def init(
        *,
        state: DatabaseState,
        sqla_models: Any,
        sessions: SessionManager,
        scope_fields: list[str],
        use_vector: bool = True,
    );
    def _normalize_embedding(embedding: Any) -> Optional[list[float]];
    def _prepare_embedding(embedding: Optional[list[float]]) -> Any;
}

glob __all__ = ["PostgresRepoBase"];
