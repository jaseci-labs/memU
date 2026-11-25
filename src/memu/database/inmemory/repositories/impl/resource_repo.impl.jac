impl InMemoryResourceRepository.init(*, state: InMemoryState, resource_model: Type[Resource]) {
    self._state = state;
    self.resource_model = resource_model;
    self.resources = self._state.resources;
}

impl InMemoryResourceRepository.list_resources(
    where: Mapping[str, Any] | None = None
) -> dict[str, Resource] {
    if not where {
        return dict(self.resources);
    }
    return {rid: res for (rid, res) in self.resources.items() if matches_where(res, where)};
}

impl InMemoryResourceRepository.clear_resources(
    where: Mapping[str, Any] | None = None
) -> dict[str, Resource] {
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

impl InMemoryResourceRepository.delete_resource(resource_id: str) {
    self.resources.pop(resource_id, None);
}

impl InMemoryResourceRepository.create_resource(
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

impl InMemoryResourceRepository.update_resource(
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

impl InMemoryResourceRepository.vector_search_resources(
    query_vec: list[float], top_k: int, where: Mapping[str, Any] | None = None
) -> list[tuple[str, float]] {
    pool = self.list_resources(where);
    corpus = [(rid, res.embedding) for (rid, res) in pool.items() if res.embedding];
    return cosine_topk(query_vec, corpus, k=top_k);
}

impl InMemoryResourceRepository.load_existing {
    return None;
}
