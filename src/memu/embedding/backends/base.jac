import from typing { Any }

class EmbeddingBackend {
    static has name: any = "base";

    static has embedding_endpoint: any = "/embeddings";

    def default_headers(api_key: str) -> dict[str, str] {
        return {"Authorization": f"Bearer {api_key}"};
    }

    def build_embedding_payload(*, inputs: list[str], embed_model: str) -> dict[str, Any] {
        raise NotImplementedError();
    }

    def parse_embedding_response(data: dict[str, Any]) -> list[list[float]] {
        raise NotImplementedError();
    }
}
