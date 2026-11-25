import from typing { Any, cast }

class VoyageEmbeddingBackend(EmbeddingBackend) {
    static has name: str = "voyage",
               embedding_endpoint: str = "/embeddings";
    def build_embedding_payload(*, inputs: list[str], embed_model: str) -> dict[str, Any];
    def parse_embedding_response(data: dict[str, Any]) -> list[list[float]];
}
