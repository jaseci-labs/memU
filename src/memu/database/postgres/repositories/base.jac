import logging;
import from collections.abc { Mapping }
import from typing { Any }
import pendulum;
glob logger = logging.getLogger(__name__);

class PostgresRepoBase {
    has _use_vector: bool,
        _scope_fields: list[str],
        _sessions: SessionManager,
        _sqla_models: Any,
        _state: DatabaseState;
    def init(
        *,
        state: DatabaseState,
        sqla_models: Any,
        sessions: SessionManager,
        scope_fields: list[str],
        use_vector: bool = True,
    );
    def _scope_kwargs_from(`obj: Any) -> dict[str, Any];
    def _normalize_embedding(embedding: Any) -> list[float] | None;
    def _prepare_embedding(embedding: list[float] | None) -> Any;
    def _merge_and_commit(`obj: Any);
    def _now -> pendulum.DateTime;
    def _build_filters(model: Any, where: Mapping[str, Any] | None) -> list[Any];
    static def _matches_where(`obj: Any, where: Mapping[str, Any] | None) -> bool;
}

glob __all__ = ["PostgresRepoBase"];
