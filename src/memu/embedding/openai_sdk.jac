import logging;
import from typing { cast }
import from openai { AsyncOpenAI, DefaultAsyncHttpxClient }
import from openai.types { CreateEmbeddingResponse }
glob logger = logging.getLogger(__name__);

class OpenAIEmbeddingSDKClient {
    has client: any,
        batch_size: int,
        embed_model: str,
        api_key: any,
        base_url: any;
    def init(*, base_url: str, api_key: str, embed_model: str, batch_size: int = 64);
    async def embed(inputs: list[str]) -> tuple[list[list[float]], CreateEmbeddingResponse | None];
}
