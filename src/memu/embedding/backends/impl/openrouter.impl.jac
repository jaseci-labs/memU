impl OpenRouterEmbeddingBackend.build_embedding_payload(
    *, inputs: list[str], embed_model: str
) -> dict[str, Any] {
    return {"model": embed_model, "input": inputs};
}

impl OpenRouterEmbeddingBackend.parse_embedding_response(
    data: dict[str, Any]
) -> list[list[float]] {
    return [cast(list[float], d["embedding"]) for d in data["data"]];
}
