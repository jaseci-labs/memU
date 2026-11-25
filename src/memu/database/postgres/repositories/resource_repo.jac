import operator;
import from typing { Type, Optional }
import from collections.abc { Mapping }
import from typing { Any }

class PostgresResourceRepo(PostgresRepoBase, ResourceRepo) {
    has _resource_model: Type[Resource];
    def init(
        *,
        state: DatabaseState,
        resource_model: Type[Resource],
        sqla_models: Any,
        sessions: SessionManager,
        scope_fields: list[str],
    );
    def list_resources(where: Mapping[str, Any] | None = None) -> dict[str, Resource];
    def clear_resources(where: Mapping[str, Any] | None = None) -> dict[str, Resource];
    def delete_resource(resource_id: str);
    def create_resource(
        *,
        url: str,
        local_path: str,
        caption: str | None,
        embedding: Optional[list[float]],
        user_data: dict[str, Any],
        track: str | None = None,
    ) -> Resource;
    def update_resource(
        *,
        resource_id: str,
        local_path: str,
        caption: str | None,
        embedding: Optional[list[float]],
        track: str | None = None,
    ) -> Resource;
    def vector_search_resources(
        query_vec: list[float], top_k: int, where: Mapping[str, Any] | None = None
    ) -> list[tuple[str, float]];
    def load_existing;
    def _cache_resource(res: Resource) -> Resource;
}

glob __all__ = ["PostgresResourceRepo"];
