impl EmbeddingBackend.default_headers(api_key: str) -> dict[str, str] {
    return {"Authorization": f"Bearer {api_key}"};
}

impl EmbeddingBackend.build_embedding_payload(
    *, inputs: list[str], embed_model: str
) -> dict[str, Any] {
    raise NotImplementedError();
}

impl EmbeddingBackend.parse_embedding_response(data: dict[str, Any]) -> list[list[float]] {
    raise NotImplementedError();
}

impl EmbeddingBackend.__repr__ -> str {
    return (getattr(builtins.object, "__repr__") as any)(self);
}

impl EmbeddingBackend.__eq__(other: any) -> bool {
    return self is other;
}

impl EmbeddingBackend.__hash__ -> int {
    return id(self);
}
