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
    ) {
        super.init(
            state=state, sqla_models=sqla_models, sessions=sessions, scope_fields=scope_fields
        );
        self._use_vector = use_vector;
    }

    def _normalize_embedding(embedding: Any) -> Optional[list[float]] {
        if embedding is None {
            return None;
        }
        if hasattr(embedding, "to_list") {
            try {
                return [float(x) for x in embedding.to_list()];
            } except Exception {
                logger.debug("Could not convert pgvector value %s", embedding);
                return None;
            }
        }
        if isinstance(embedding, str) {
            stripped = embedding.strip("[]");
            if not stripped {
                return [];
            }
            return [float(x) for x in stripped.split(",")];
        }
        try {
            return [float(x) for x in embedding];
        } except Exception {
            logger.debug("Could not normalize embedding %s", embedding);
            return None;
        }
    }

    def _prepare_embedding(embedding: Optional[list[float]]) -> Any {
        if embedding is None {
            return None;
        }
        return embedding;
    }
}

glob __all__ = ["PostgresRepoBase"];
