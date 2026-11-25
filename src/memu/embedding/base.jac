import from typing { Any }

class EmbeddingClient {
    has embed_model: str;

    async def embed(inputs: list[str]) -> tuple[list[list[float]], Any] {
        raise NotImplementedError();
    }
}
