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
