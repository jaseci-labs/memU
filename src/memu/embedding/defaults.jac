glob EMBEDDING_PROVIDER_DEFAULTS: dict[str, str],
     EMBEDDING_PROVIDER_ENDPOINTS: dict[str, tuple[str, str]],
     EMBEDDING_SDK_BASE_URLS: dict[str, str];

with entry {
    EMBEDDING_PROVIDER_DEFAULTS = {
        "openai": "text-embedding-3-small",
        "jina": "jina-embeddings-v3",
        "voyage": "voyage-3.5",
        "doubao": "doubao-embedding-large-text-250515",
        "openrouter": "openai/text-embedding-3-small",
    };
    EMBEDDING_PROVIDER_ENDPOINTS = {
        "jina": ("https://api.jina.ai/v1", "JINA_API_KEY"),
        "voyage": ("https://api.voyageai.com/v1", "VOYAGE_API_KEY"),
        "doubao": ("https://ark.cn-beijing.volces.com", "ARK_API_KEY"),
        "openrouter": ("https://openrouter.ai", "OPENROUTER_API_KEY"),
    };
    EMBEDDING_SDK_BASE_URLS = {"openrouter": "https://openrouter.ai/api/v1"};
}

def default_embedding_model(provider: str) -> str | None;
