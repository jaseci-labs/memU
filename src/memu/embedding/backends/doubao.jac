import base64;
import struct;
import from typing { Any, Literal, cast }

class DoubaoMultimodalEmbeddingInput {
    has content: str,
        input_type: Literal["text", "image_url", "video_url"];
    def init(input_type: Literal["text", "image_url", "video_url"], content: str);
    def to_dict -> dict[str, Any];
}

class DoubaoEmbeddingBackend(EmbeddingBackend) {
    static has name: str = "doubao",
               embedding_endpoint: str = "/api/v3/embeddings",
               multimodal_embedding_endpoint: str = "/api/v3/embeddings/multimodal";
    def build_embedding_payload(*, inputs: list[str], embed_model: str) -> dict[str, Any];
    def parse_embedding_response(data: dict[str, Any]) -> list[list[float]];
    def build_multimodal_embedding_payload(
        *,
        inputs: list[DoubaoMultimodalEmbeddingInput],
        embed_model: str,
        encoding_format: str = "float",
    ) -> dict[str, Any];
    def parse_multimodal_embedding_response(data: dict[str, Any]) -> list[list[float]];
}
