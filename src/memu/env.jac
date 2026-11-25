import importlib;
import codecs;
import locale;
import math;
import os;
import from functools { cache }
import from pathlib { Path }
import from typing { TYPE_CHECKING, Any, Literal, Optional }
glob CONFIG_ENV = "~/.memu/config.env";

class ConfigError(RuntimeError) {
    def init(name: str, detail: str | None = None);
}

glob _ENV_PASSTHROUGH = ("NO_PROXY", "no_proxy");

def read_config(path: Path) -> tuple[str, bool];
@cache
def _file_values -> dict[str, str];
def reload;
def env(name: str, `default: str | None = None) -> str | None;
def env_declared(name: str, `default: str = "") -> str;
def require(name: str) -> str;
def database_config(db: str) -> dict[str, Any];
def embedding_provider -> str;
def embedding_profile -> dict[str, Any];
glob QueryKind = Literal["short", "long", "extracted"],
     LONG_QUERY_CHARS = 200,
     _CLOUD_RETRIEVAL_MIN_SCORES: dict[QueryKind, float] = {
         "short": 0.55,
         "long": 0.6,
         "extracted": 0.58,
     };
def retrieval_min_score(kind: QueryKind) -> float | None;
glob MemoryMode = Literal["local", "cloud"];
def memory_mode -> MemoryMode;
def cloud_base_url -> str;
def cloud_api_key -> str;
def build_agentic_memory_backend_from_env(
    *, local_database: str | None = None, local_embedding_profile: Optional[dict[str, Any]] = None
) -> any;
def build_service_from_env -> Any;
