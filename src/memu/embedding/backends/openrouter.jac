import from typing { Any, cast }

class OpenRouterEmbeddingBackend(EmbeddingBackend) {
    static has name: str = "openrouter",
               embedding_endpoint: str = "/api/v1/embeddings";
    def build_embedding_payload(*, inputs: list[str], embed_model: str) -> dict[str, Any];
    def parse_embedding_response(data: dict[str, Any]) -> list[list[float]];
}
