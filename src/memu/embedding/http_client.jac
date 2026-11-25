import importlib;
import asyncio;
import ipaddress;
import logging;
import urllib.parse;
import urllib.request;
import from collections.abc { Callable }
import from typing { Any, Literal, Optional }
import httpx;

def is_loopback_url(url: str) -> bool {
    host = urllib.parse.urlsplit(url).hostname or "";
    localhost = host.removesuffix(".");
    if localhost == "localhost" or localhost.endswith(".localhost") {
        return True;
    }
    try {
        return ipaddress.ip_address(host).is_loopback;
    } except ValueError {
        return False;
    }
}

def proxy_bypass_mounts(url: str) -> Optional[dict[str, httpx.AsyncBaseTransport | None]] {
    if not is_loopback_url(url) {
        return None;
    }
    host = urllib.parse.urlsplit(url).hostname or "";
    if ":" in host {
        host = f"[{host}]";
    }
    return {f"all://{host}": None};
}

def _load_proxy(base_url: str) -> str | None {
    memu_env = importlib.import_module("memu.env").env;
    explicit = memu_env("MEMU_HTTP_PROXY") or None;
    if explicit or is_loopback_url(base_url) {
        return explicit;
    }
    target = urllib.parse.urlsplit(base_url);
    proxies = urllib.request.getproxies_environment();
    if urllib.request.proxy_bypass(target.netloc) {
        return None;
    }
    if target.scheme.lower() == "https" {
        return proxies.get("https") or proxies.get("http") or proxies.get("all");
    }
    return proxies.get("http") or proxies.get("all") if target.scheme.lower() == "http" else None;
}

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
        endpoint_overrides: Optional[dict[str, str]] = None,
        timeout: int = 60,
        embed_batch_size: int = 64,
        max_attempts: int = DEFAULT_MAX_ATTEMPTS,
    ) {
        self.base_url = base_url.rstrip("/") + "/";
        self.api_key = api_key or "";
        self.embed_model = embed_model;
        self.provider = provider.lower();
        self.backend = self._load_backend(self.provider);
        overrides = endpoint_overrides or {};
        raw_embedding_ep = overrides.get("embeddings")
            or overrides.get("embedding")
            or overrides.get("embed")
            or self.backend.embedding_endpoint;
        self.embedding_endpoint = raw_embedding_ep.lstrip("/");
        self.timeout = timeout;
        self.embed_batch_size = max(1, embed_batch_size);
        self.max_attempts = max(1, max_attempts);
        self.proxy = _load_proxy(self.base_url);
        self.mounts = proxy_bypass_mounts(self.base_url) if self.proxy is None else None;
    }

    async def embed(inputs: list[str]) -> tuple[list[list[float]], dict[str, Any]] {
        if not inputs {
            return ([], {});
        }
        vectors: list[list[float]] = [];
        data: dict[str, Any] = {};
        # Called through its class, the backend's vectors keep their type: read
        # through the `any` field they would be converted float by float again.
        backend: EmbeddingBackend = self.backend;
        async with httpx.AsyncClient(
            base_url=self.base_url, timeout=self.timeout, proxy=self.proxy, mounts=self.mounts
        ) as client {
            for start in range(0, len(inputs), self.embed_batch_size) {
                batch = inputs[start:start + self.embed_batch_size];
                data = await self._post_embeddings(client, batch);
                logger.debug("HTTP embedding response: %s", data);
                vectors.extend(backend.parse_embedding_response(data));
            }
        }
        return (vectors, data);
    }

    async def _post_embeddings(client: httpx.AsyncClient, batch: list[str]) -> dict[str, Any] {
        payload = self.backend.build_embedding_payload(inputs=batch, embed_model=self.embed_model);
        for attempt in range(1, self.max_attempts + 1) {
            try {
                resp = await client.post(
                    self.embedding_endpoint, json=payload, headers=self._headers()
                );
            } except httpx.TransportError {
                if attempt == self.max_attempts {
                    raise;
                }
                await asyncio.sleep(retry_delay(attempt));
                continue;
            }
            if resp.status_code in RETRYABLE_STATUS_CODES and attempt < self.max_attempts {
                logger.debug(
                    "embedding request returned %s; retry %s/%s",
                    resp.status_code,
                    attempt,
                    self.max_attempts,
                );
                await asyncio.sleep(retry_delay(attempt, resp));
                continue;
            }
            resp.raise_for_status();
            json_data: dict[str, Any] = resp.json();
            return json_data;
        }
        raise AssertionError(_UNREACHABLE_RETRY);
    }

    async def embed_multimodal(
        inputs: list[tuple[Literal["text", "image_url", "video_url"], str]],
        *,
        encoding_format: str = "float",
    ) -> list[list[float]] {
        if not isinstance(self.backend, DoubaoEmbeddingBackend) {
            raise TypeError(
                f"Multimodal embedding is only supported by 'doubao' provider, but current provider is '{self.provider}'",
            );
        }
        multimodal_inputs = [
            DoubaoMultimodalEmbeddingInput(input_type=input_type, content=content)
            for (input_type, content) in inputs
        ];
        payload = self.backend.build_multimodal_embedding_payload(
            inputs=multimodal_inputs, embed_model=self.embed_model, encoding_format=encoding_format
        );
        endpoint = self.backend.multimodal_embedding_endpoint.lstrip("/");
        async with httpx.AsyncClient(
            base_url=self.base_url, timeout=self.timeout, proxy=self.proxy, mounts=self.mounts
        ) as client {
            resp = await client.post(endpoint, json=payload, headers=self._headers());
            resp.raise_for_status();
            data = resp.json();
        }
        logger.debug("HTTP multimodal embedding response: %s", data);
        return self.backend.parse_multimodal_embedding_response(data);
    }

    def _headers -> dict[str, str] {
        return self.backend.default_headers(self.api_key);
    }

    def _load_backend(provider: str) -> EmbeddingBackend {
        factory = EMBEDDING_BACKENDS.get(provider, OpenAIEmbeddingBackend);
        return factory();
    }
}
