import importlib;
import from collections.abc { Callable }
import from typing { TYPE_CHECKING, Any }
def _build_sdk_client(cfg: EmbeddingConfig) -> Any;
def _build_httpx_client(cfg: EmbeddingConfig) -> Any;
glob EMBEDDING_CLIENT_BUILDERS: any;

with entry {
    EMBEDDING_CLIENT_BUILDERS = {"sdk": _build_sdk_client, "httpx": _build_httpx_client};
}

def build_embedding_client(cfg: EmbeddingConfig) -> Any;
