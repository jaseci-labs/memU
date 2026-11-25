import from typing { Type, Optional }
import uuid;
import from collections.abc { Mapping }
import from typing { Any }
import pendulum;

class InMemoryResourceRepository(ResourceRepoProtocol) {
    has resources: dict[str, Resource],
        resource_model: Type[Resource],
        _state: InMemoryState;

    def init(*, state: InMemoryState, resource_model: Type[Resource]) {
        self._state = state;
        self.resource_model = resource_model;
        self.resources = self._state.resources;
    }

    def list_resources(where: Mapping[str, Any] | None = None) -> dict[str, Resource] {
        return dict(self.resources)
            if not where
            else ({rid: res for (rid, res) in self.resources.items() if matches_where(res, where)});
    }

    def clear_resources(where: Mapping[str, Any] | None = None) -> dict[str, Resource] {
        if not where {
            matches = self.resources.copy();
            self.resources.clear();
            return matches;
        }
        matches = {rid: res for (rid, res) in self.resources.items() if matches_where(res, where)};
        for rid in matches {
            self.resources.pop(rid, None);
        }
        return matches;
    }

    def delete_resource(resource_id: str) {
        self.resources.pop(resource_id, None);
    }

    def create_resource(
        *,
        url: str,
        local_path: str,
        caption: str | None,
        embedding: Optional[list[float]],
        user_data: dict[str, Any],
        track: str | None = None,
    ) -> Resource {
        rid = str(uuid.uuid4());
        res = self.resource_model(
            id=rid,
            url=url,
            local_path=local_path,
            caption=caption,
            embedding=embedding,
            track=track,
            **user_data,
        );
        self.resources[rid] = res;
        return res;
    }

    def update_resource(
        *,
        resource_id: str,
        local_path: str,
        caption: str | None,
        embedding: Optional[list[float]],
        track: str | None = None,
    ) -> Resource {
        res = self.resources.get(resource_id);
        if res is None {
            raise KeyError(f"Resource with id {resource_id} not found");
        }
        res.local_path = local_path;
        res.caption = caption;
        res.embedding = embedding;
        res.track = track;
        res.updated_at = pendulum.now("UTC");
        return res;
    }

    def vector_search_resources(
        query_vec: list[float], top_k: int, where: Mapping[str, Any] | None = None
    ) -> list[tuple[str, float]] {
        pool = self.list_resources(where);
        corpus = [(rid, res.embedding) for (rid, res) in pool.items() if res.embedding];
        return cosine_topk(query_vec, corpus, k=top_k);
    }

    def load_existing {
        return None;
    }
}

glob ResourceRepo: any;

with entry {
    ResourceRepo = InMemoryResourceRepository;
}

glob __all__ = ["InMemoryResourceRepository", "ResourceRepo"];
