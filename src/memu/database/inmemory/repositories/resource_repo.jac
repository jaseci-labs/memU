import from typing { Type, Optional }
import uuid;
import from collections.abc { Mapping }
import from typing { Any }
import pendulum;

class InMemoryResourceRepository(ResourceRepoProtocol) {
    has resources: dict[str, Resource],
        resource_model: Type[Resource],
        _state: InMemoryState;
    def init(*, state: InMemoryState, resource_model: Type[Resource]);
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

glob ResourceRepo: any;

with entry {
    ResourceRepo = InMemoryResourceRepository;
}

glob __all__ = ["InMemoryResourceRepository", "ResourceRepo"];
