import json;
import logging;
import from typing { Any, Optional }
glob logger = logging.getLogger(__name__);

class SQLiteRepoBase(SQLRepoBase) {
    # Every row's vector passes through here on each retrieve: map(float, ...)
    # makes the same list as a comprehension, in about half the time.
    def _normalize_embedding(embedding: Any) -> Optional[list[float]] {
        if embedding is None {
            return None;
        }
        if isinstance(embedding, str) {
            try {
                return list(map(float, json.loads(embedding)));
            } except (json.JSONDecodeError, TypeError) {
                logger.debug("Could not parse embedding JSON: %s", embedding);
                return None;
            }
        }
        try {
            return list(map(float, embedding));
        } except (ValueError, TypeError, OverflowError) {
            logger.debug("Could not normalize embedding %s", embedding);
            return None;
        }
    }

    def _prepare_embedding(embedding: Optional[list[float]]) -> Optional[list[float]] {
        return None if embedding is None else list(embedding);
    }
}
