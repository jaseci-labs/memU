import importlib;
import from typing { Type, Optional }
import from typing { Annotated, Any, Literal }
import from pydantic {
    BaseModel,
    BeforeValidator,
    Field,
    RootModel,
    StringConstraints,
    model_validator,
}

def normalize_value(v: str) -> str {
    return v.strip().lower() if isinstance(v, str) else v;
}

glob Normalize: any;

with entry {
    Normalize = BeforeValidator(normalize_value);
}

class EmbeddingConfig(BaseModel) {
    has provider: str = Field(
            default="openai",
            description="Identifier for the embedding provider implementation (used by HTTP client backend).",
        ),
        base_url: str = Field(default="https://api.openai.com/v1"),
        api_key: str = Field(default="OPENAI_API_KEY"),
        embed_model: str = Field(
            default="text-embedding-3-small", description="Embedding model used for vectorization."
        ),
        embed_batch_size: int = Field(
            default=64,
            ge=1,
            description="Maximum number of texts per embedding request. Longer input lists are split into that many sequential requests. 64 is well under every supported provider's input limit (OpenAI/Jina 2048, Voyage 128); lower it only for a provider that rejects it.",
        ),
        client_backend: str = Field(
            default="sdk",
            description="Which embedding client backend to use: 'sdk' (official OpenAI SDK) or 'httpx' (raw HTTP, supports all providers in memu.embedding.backends, e.g. openai/jina/voyage/doubao/openrouter).",
        ),
        endpoint_overrides: dict[str, str] = Field(
            default_factory=dict[any, any],
            description="Optional overrides for HTTP endpoints (key: 'embeddings').",
        );

    @model_validator(mode="after")
    def set_provider_defaults -> EmbeddingConfig {
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
}

class RetrieveResourceConfig(BaseModel) {
    has enabled: bool = Field(default=True, description="Whether to enable resource retrieval."),
        top_k: int = Field(default=5, description="Total number of resources to retrieve.");
}

class RetrieveFileConfig(BaseModel) {
    has enabled: bool = Field(default=True, description="Whether to enable file retrieval."),
        top_k: int = Field(default=5, description="Total number of files to retrieve."),
        tracks: Optional[list[str]] = Field(
            default=None,
            description="Optional file tracks (e.g. ['memory', 'skill']) to filter on. None means all tracks.",
        );
}

class ProgressiveRetrieveConfig(BaseModel) {
    has file: RetrieveFileConfig = Field(default=RetrieveFileConfig()),
        resource: RetrieveResourceConfig = Field(default=RetrieveResourceConfig());
}

class DefaultUserModel(BaseModel) {
    has user_id: str | None = None,
        agent_id: str | None = None;
}

class UserConfig(BaseModel) {
    has model: Type[BaseModel] = Field(default=DefaultUserModel);
}

glob Key = Annotated[str, StringConstraints(min_length=1)],
     _ProfilesBase: any;

with entry {
    _ProfilesBase = RootModel[dict[Key, EmbeddingConfig]];
}

class EmbeddingProfilesConfig(_ProfilesBase) {
    has `root: dict[str, EmbeddingConfig] = Field(
        default_factory=lambda -> any { {"default": EmbeddingConfig()} }
    );

    def get(key: str, `default: EmbeddingConfig | None = None) -> EmbeddingConfig | None {
        return self.root.get(key, `default);
    }

    @model_validator(mode="before")
    class def ensure_default(data: Any) -> Any {
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

    has profiles: dict[str, EmbeddingConfig] {
        getter {
            return self.root;
        }
    }

    has `default: EmbeddingConfig {
        getter {
            return self.root.get("default", EmbeddingConfig());
        }
    }
}

class MetadataStoreConfig(BaseModel) {
    has provider: Annotated[Literal["inmemory", "postgres", "sqlite"], Normalize] = "inmemory",
        ddl_mode: Annotated[Literal["create", "validate"], Normalize] = "create",
        dsn: str | None = Field(
            default=None, description="Database connection string (required for postgres/sqlite)."
        );
}

class VectorIndexConfig(BaseModel) {
    has provider: Annotated[Literal["bruteforce", "pgvector", "none"], Normalize] = "bruteforce",
        dsn: str | None = Field(
            default=None, description="Postgres connection string when provider=pgvector."
        );
}

class DatabaseConfig(BaseModel) {
    has metadata_store: MetadataStoreConfig = Field(default_factory=MetadataStoreConfig),
        vector_index: VectorIndexConfig | None = Field(default=None);

    def model_post_init(__context: Any) {
        if self.vector_index is None {
            if self.metadata_store.provider == "postgres" {
                self.vector_index = VectorIndexConfig(
                    provider="pgvector", dsn=self.metadata_store.dsn
                );
            } else {
                self.vector_index = VectorIndexConfig(provider="bruteforce");
            }
        } elif self.vector_index.provider == "pgvector" and self.vector_index.dsn is None {
            self.vector_index = self.vector_index.model_copy(
                update={"dsn": self.metadata_store.dsn}
            );
        }
    }
}
