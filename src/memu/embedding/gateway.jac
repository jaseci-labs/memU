import from collections.abc { Callable }
import from typing { TYPE_CHECKING, Any }
def _build_sdk_client(cfg: EmbeddingConfig) -> Any;
def _build_httpx_client(cfg: EmbeddingConfig) -> Any;
glob EMBEDDING_CLIENT_BUILDERS: dict[str, Callable[[EmbeddingConfig], Any]] = {
    "sdk": _build_sdk_client,
    "httpx": _build_httpx_client,
};
def build_embedding_client(cfg: EmbeddingConfig) -> Any;
