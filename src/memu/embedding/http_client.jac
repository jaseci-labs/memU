import asyncio;
import ipaddress;
import logging;
import urllib.parse;
import urllib.request;
import from collections.abc { Callable }
import from typing { Any, Literal }
import httpx;
def is_loopback_url(url: str) -> bool;
def proxy_bypass_mounts(url: str) -> dict[str, httpx.AsyncBaseTransport | None] | None;
def _load_proxy(base_url: str) -> str | None;
glob logger = logging.getLogger(__name__),
     _UNREACHABLE_RETRY = "embedding retry loop exited without a response",
     EMBEDDING_BACKENDS: dict[str, Callable[[], EmbeddingBackend]] = {
         OpenAIEmbeddingBackend.name: OpenAIEmbeddingBackend,
         DoubaoEmbeddingBackend.name: DoubaoEmbeddingBackend,
         JinaEmbeddingBackend.name: JinaEmbeddingBackend,
         VoyageEmbeddingBackend.name: VoyageEmbeddingBackend,
         OpenRouterEmbeddingBackend.name: OpenRouterEmbeddingBackend,
     };

class HTTPEmbeddingClient {
    has mounts: any,
        proxy: any,
        max_attempts: any,
        embed_batch_size: any,
        timeout: int,
        embedding_endpoint: any,
        backend: any,
        provider: any,
        embed_model: str,
        api_key: any,
        base_url: any;
    def init(
        *,
        base_url: str,
        api_key: str,
        embed_model: str,
        provider: str = "openai",
        endpoint_overrides: dict[str, str] | None = None,
        timeout: int = 60,
        embed_batch_size: int = 64,
        max_attempts: int = DEFAULT_MAX_ATTEMPTS,
    );
    async def embed(inputs: list[str]) -> tuple[list[list[float]], dict[str, Any]];
    async def _post_embeddings(client: httpx.AsyncClient, batch: list[str]) -> dict[str, Any];
    async def embed_multimodal(
        inputs: list[tuple[Literal["text", "image_url", "video_url"], str]],
        *,
        encoding_format: str = "float",
    ) -> list[list[float]];
    def _headers -> dict[str, str];
    def _load_backend(provider: str) -> EmbeddingBackend;
}
