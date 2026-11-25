import from typing { Any, cast }

class JinaEmbeddingBackend(EmbeddingBackend) {
    static has name: str = "jina",
               embedding_endpoint: str = "/embeddings";

    def build_embedding_payload(*, inputs: list[str], embed_model: str) -> dict[str, Any] {
        return {"model": embed_model, "input": inputs};
    }

    def parse_embedding_response(data: dict[str, Any]) -> list[list[float]] {
        return [cast(list[float], d["embedding"]) for d in data["data"]];
    }
}
