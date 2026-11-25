impl normalize_value(v: str) -> str {
    if isinstance(v, str) {
        return v.strip().lower();
    }
    return v;
}

impl EmbeddingConfig.set_provider_defaults -> EmbeddingConfig {
    defaults = importlib.import_module("memu.embedding.defaults");
    endpoint = defaults.EMBEDDING_PROVIDER_ENDPOINTS.get(self.provider);
    if endpoint is not None {
        (base_url, api_key) = endpoint;
        if self.base_url == "https://api.openai.com/v1" {
            self.base_url = defaults.EMBEDDING_SDK_BASE_URLS.get(self.provider, base_url)
                if self.client_backend == "sdk"
                else base_url;
        }
        if self.api_key == "OPENAI_API_KEY" {
            self.api_key = api_key;
        }
    }
    if self.embed_model == "text-embedding-3-small" {
        resolved = defaults.default_embedding_model(self.provider);
        if resolved is not None {
            self.embed_model = resolved;
        }
    }
    return self;
}

impl EmbeddingProfilesConfig.get(
    key: str, `default: EmbeddingConfig | None = None
) -> EmbeddingConfig | None {
    return self.root.get(key, `default);
}

impl EmbeddingProfilesConfig.ensure_default(data: Any) -> Any {
    if data is None {
        data = {};
    } elif isinstance(data, dict) {
        data = dict(data);
    } else {
        return data;
    }
    if "default" not in data {
        data["default"] = EmbeddingConfig();
    }
    if "embedding" not in data {
        data["embedding"] = data["default"];
    }
    return data;
}

impl DatabaseConfig.model_post_init(__context: Any) {
    if self.vector_index is None {
        if self.metadata_store.provider == "postgres" {
            self.vector_index = VectorIndexConfig(provider="pgvector", dsn=self.metadata_store.dsn);
        } else {
            self.vector_index = VectorIndexConfig(provider="bruteforce");
        }
    } elif self.vector_index.provider == "pgvector" and self.vector_index.dsn is None {
        self.vector_index = self.vector_index.model_copy(update={"dsn": self.metadata_store.dsn});
    }
}
