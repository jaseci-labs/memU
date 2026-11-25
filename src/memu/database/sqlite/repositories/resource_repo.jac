import from typing { Type, Optional }
import logging;
import from collections.abc { Mapping }
import from typing { Any }
import from sqlmodel { delete, select }
glob logger = logging.getLogger(__name__);

class SQLiteResourceRepo(SQLiteRepoBase, ResourceRepo) {
    has _record_model: Type[Resource],
        _resource_model: Type[Any];
    def init(
        *,
        state: DatabaseState,
        resource_model: Type[Any],
        sqla_models: SQLiteSQLAModels,
        sessions: SQLiteSessionManager,
        scope_fields: list[str],
        record_model: Type[Resource] = Resource,
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
}

glob __all__ = ["SQLiteResourceRepo"];
