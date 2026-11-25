import logging;
import from openai { AsyncOpenAI, DefaultAsyncHttpxClient }
import from openai.types { CreateEmbeddingResponse }
glob logger = logging.getLogger(__name__);

class OpenAIEmbeddingSDKClient {
    has client: any,
        batch_size: int,
        embed_model: str,
        api_key: any,
        base_url: any;

    def init(*, base_url: str, api_key: str, embed_model: str, batch_size: int = 64) {
        self.base_url = base_url.rstrip("/");
        self.api_key = api_key or "";
        self.embed_model = embed_model;
        self.batch_size = batch_size;
        proxy = _load_proxy(self.base_url);
        http_client: DefaultAsyncHttpxClient | None;
        if proxy {
            http_client = DefaultAsyncHttpxClient(proxy=proxy);
        } else {
            mounts = proxy_bypass_mounts(self.base_url);
            http_client = DefaultAsyncHttpxClient(mounts=mounts) if mounts else None;
        }
        self.client = AsyncOpenAI(
            api_key=self.api_key, base_url=self.base_url, http_client=http_client
        );
    }

    async def embed(inputs: list[str]) -> tuple[list[list[float]], CreateEmbeddingResponse | None] {
        if not inputs {
            return ([], None);
        }
        if len(inputs) <= self.batch_size {
            response = await self.client.embeddings.create(model=self.embed_model, input=inputs);
            return ([[float(x) for x in d.embedding] for d in response.data], response);
        }
        all_embeddings: list[list[float]] = [];
        last_response: CreateEmbeddingResponse | None = None;
        for i in range(0, len(inputs), self.batch_size) {
            batch = inputs[i:i + self.batch_size];
            response = await self.client.embeddings.create(model=self.embed_model, input=batch);
            all_embeddings.extend([[float(x) for x in d.embedding] for d in response.data]);
            last_response = response;
        }
        return (all_embeddings, last_response);
    }
}
