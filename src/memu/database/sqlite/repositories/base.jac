import json;
import logging;
import from typing { Any, Optional }
glob logger = logging.getLogger(__name__);

class SQLiteRepoBase(SQLRepoBase) {
    def _normalize_embedding(embedding: Any) -> Optional[list[float]];
    def _prepare_embedding(embedding: Optional[list[float]]) -> Optional[list[float]];
}

glob __all__ = ["SQLiteRepoBase"];
