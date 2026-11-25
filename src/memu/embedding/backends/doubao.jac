import base64;
import struct;
import from typing { Any, Literal, cast }

class DoubaoMultimodalEmbeddingInput {
    has content: str,
        input_type: Literal["text", "image_url", "video_url"];

    def init(input_type: Literal["text", "image_url", "video_url"], content: str) {
        self.input_type = input_type;
        self.content = content;
    }

    def to_dict -> dict[str, Any] {
        if self.input_type == "text" {
            return {"type": "text", "text": self.content};
        } elif self.input_type == "image_url" {
            return {"type": "image_url", "image_url": {"url": self.content}};
        } elif self.input_type == "video_url" {
            return {"type": "video_url", "video_url": {"url": self.content}};
        } else {
            raise ValueError(f"Unsupported input type: {self.input_type}");
        }
    }
}

class DoubaoEmbeddingBackend(EmbeddingBackend) {
    static has name: str = "doubao",
               embedding_endpoint: str = "/api/v3/embeddings",
               multimodal_embedding_endpoint: str = "/api/v3/embeddings/multimodal";

    def build_embedding_payload(*, inputs: list[str], embed_model: str) -> dict[str, Any] {
        return {"model": embed_model, "input": inputs, "encoding_format": "float"};
    }

    def parse_embedding_response(data: dict[str, Any]) -> list[list[float]] {
        return [cast(list[float], d["embedding"]) for d in data["data"]];
    }

    def build_multimodal_embedding_payload(
        *,
        inputs: list[DoubaoMultimodalEmbeddingInput],
        embed_model: str,
        encoding_format: str = "float",
    ) -> dict[str, Any] {
        return {
            "model": embed_model,
            "encoding_format": encoding_format,
            "input": [inp.to_dict() for inp in inputs],
        };
    }

    def parse_multimodal_embedding_response(data: dict[str, Any]) -> list[list[float]] {
        result = data["data"];
        items = [result] if isinstance(result, dict) else result;
        vectors: list[list[float]] = [];
        for item in items {
            embedding = item["embedding"];
            if isinstance(embedding, str) {
                raw = base64.b64decode(embedding, validate=True);
                embedding = [value for (value,) in struct.iter_unpack("<f", raw)];
            }
            vectors.append(cast(list[float], embedding));
        }
        return vectors;
    }
}
