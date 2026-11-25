import importlib;
import from typing { Any }

def _build_sdk_client(cfg: EmbeddingConfig) -> Any {
    OpenAIEmbeddingSDKClient = importlib.import_module(
        "memu.embedding.openai_sdk"
    ).OpenAIEmbeddingSDKClient;
    return OpenAIEmbeddingSDKClient(
        base_url=cfg.base_url,
        api_key=cfg.api_key,
        embed_model=cfg.embed_model,
        batch_size=cfg.embed_batch_size,
    );
}

def _build_httpx_client(cfg: EmbeddingConfig) -> Any {
    HTTPEmbeddingClient = importlib.import_module("memu.embedding.http_client").HTTPEmbeddingClient;
    return HTTPEmbeddingClient(
        base_url=cfg.base_url,
        api_key=cfg.api_key,
        embed_model=cfg.embed_model,
        provider=cfg.provider,
        endpoint_overrides=cfg.endpoint_overrides,
        embed_batch_size=cfg.embed_batch_size,
    );
}

glob EMBEDDING_CLIENT_BUILDERS: any;

with entry {
    EMBEDDING_CLIENT_BUILDERS = {"sdk": _build_sdk_client, "httpx": _build_httpx_client};
}

def build_embedding_client(cfg: EmbeddingConfig) -> Any {
    builder = EMBEDDING_CLIENT_BUILDERS.get(cfg.client_backend);
    if builder is None {
        available = ", ".join(sorted(EMBEDDING_CLIENT_BUILDERS));
        raise ValueError(
            f"Unknown embedding client_backend '{cfg.client_backend}'. Available: {available}"
        );
    }
    return builder(cfg);
}
