import from typing { Any }

class EmbeddingBackend {
    static has name: any = "base";

    static has embedding_endpoint: any = "/embeddings";
    def default_headers(api_key: str) -> dict[str, str];

    def build_embedding_payload(*, inputs: list[str], embed_model: str) -> dict[str, Any];

    def parse_embedding_response(data: dict[str, Any]) -> list[list[float]];
}
