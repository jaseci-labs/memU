import from typing { Type }
import from typing { Annotated, Any, Literal }
import from pydantic {
    BaseModel,
    BeforeValidator,
    Field,
    RootModel,
    StringConstraints,
    model_validator,
}
def normalize_value(v: str) -> str;
glob Normalize = BeforeValidator(normalize_value);

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
    def set_provider_defaults -> EmbeddingConfig;
}

class RetrieveResourceConfig(BaseModel) {
    has enabled: bool = Field(default=True, description="Whether to enable resource retrieval."),
        top_k: int = Field(default=5, description="Total number of resources to retrieve.");
}

class RetrieveFileConfig(BaseModel) {
    has enabled: bool = Field(default=True, description="Whether to enable file retrieval."),
        top_k: int = Field(default=5, description="Total number of files to retrieve."),
        tracks: list[str] | None = Field(
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
     _ProfilesBase: any = RootModel[dict[Key, EmbeddingConfig]];

class EmbeddingProfilesConfig(_ProfilesBase) {
    has `root: dict[str, EmbeddingConfig] = Field(
        default_factory=lambda -> any { {"default": EmbeddingConfig()} }
    );
    def get(key: str, `default: EmbeddingConfig | None = None) -> EmbeddingConfig | None;
    @model_validator(mode="before")
    class def ensure_default(data: Any) -> Any;

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
    def model_post_init(__context: Any);
}
