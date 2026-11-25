import from collections.abc { Mapping }
import from typing { Any, Protocol, runtime_checkable, Optional }

@runtime_checkable
class ResourceRepo(Protocol) {
    has resources: dict[str, Resource];
    def list_resources(where: Mapping[str, Any] | None = None) -> dict[str, Resource] abst;
    def clear_resources(where: Mapping[str, Any] | None = None) -> dict[str, Resource] abst;
    def delete_resource(resource_id: str) abst;
    def create_resource(
        *,
        url: str,
        local_path: str,
        caption: str | None,
        embedding: Optional[list[float]],
        user_data: dict[str, Any],
        track: str | None = None,
    ) -> Resource abst;
    def update_resource(
        *,
        resource_id: str,
        local_path: str,
        caption: str | None,
        embedding: Optional[list[float]],
        track: str | None = None,
    ) -> Resource abst;
    def vector_search_resources(
        query_vec: list[float], top_k: int, where: Mapping[str, Any] | None = None
    ) -> list[tuple[str, float]] abst;
    def load_existing abst;
}
