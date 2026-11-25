import operator;
import builtins;
import json;
import logging;
import from collections.abc { Mapping }
import from typing { Any, Optional }
import pendulum;
glob logger = logging.getLogger(__name__);

class SQLiteRepoBase(builtins.object) {
    has _scope_fields: list[str],
        _sessions: SQLiteSessionManager,
        _sqla_models: Any,
        _state: DatabaseState;
    def init(
        *,
        state: DatabaseState,
        sqla_models: Any,
        sessions: SQLiteSessionManager,
        scope_fields: list[str],
    );
    def _scope_kwargs_from(`obj: Any) -> dict[str, Any];
    def _normalize_embedding(embedding: Any) -> Optional[list[float]];
    def _prepare_embedding(embedding: Optional[list[float]]) -> Optional[list[float]];
    def _merge_and_commit(`obj: Any);
    def _now -> pendulum.DateTime;
    def _build_filters(model: Any, where: Mapping[str, Any] | None) -> list[Any];
    static def _matches_where(`obj: Any, where: Mapping[str, Any] | None) -> bool;
}

glob __all__ = ["SQLiteRepoBase"];
