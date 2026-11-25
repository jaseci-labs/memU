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
    def init(name: str, detail: str | None = None) {
        if detail is not None {
            super.init(f"{name}: {detail}");
            return;
        }
        super.init(
            f"{name} is not set. Add it to {CONFIG_ENV} (or export it). Refusing to fall back to a default: record and retrieval must use the same store, or retrieval finds nothing.",
        );
    }
}

glob _ENV_PASSTHROUGH = ("NO_PROXY", "no_proxy");

def read_config(path: Path) -> tuple[str, bool] {
    data = path.read_bytes();
    if data.startswith(codecs.BOM_UTF8) {
        return (data.decode("utf-8-sig"), False);
    }
    if data.startswith((codecs.BOM_UTF16_LE, codecs.BOM_UTF16_BE)) {
        return (data.decode("utf-16"), False);
    }
    try {
        return (data.decode("utf-8"), True);
    } except UnicodeDecodeError {
        if os.name != "nt" {
            raise;
        }
        return (data.decode(locale.getencoding()), False);
    }
}

@cache
def _file_values -> dict[str, str] {
    path = Path(os.path.expanduser(os.environ.get("MEMU_CONFIG_ENV", CONFIG_ENV)));
    if not path.is_file() {
        return {};
    }
    values: dict[str, str] = {};
    (text, _) = read_config(path);
    for raw in text.splitlines() {
        line = raw.strip();
        if not line or line.startswith("#") {
            continue;
        }
        (key, sep, value) = line.partition("=");
        if sep {
            values[key.strip()] = value.strip().strip("\"'");
        }
    }
    for key in _ENV_PASSTHROUGH {
        if key in values {
            os.environ.setdefault(key, values[key]);
        }
    }
    return values;
}

def reload {
    _file_values.cache_clear();
}

def env(name: str, `default: str | None = None) -> str | None {
    return os.environ.get(name) or _file_values().get(name) or `default;
}

def env_declared(name: str, `default: str = "") -> str {
    if name in os.environ {
        return os.environ[name];
    }
    values = _file_values();
    return values[name] if name in values else `default;
}

def require(name: str) -> str {
    value = env(name);
    if not value {
        raise ConfigError(name);
    }
    return value;
}

def database_config(db: str) -> dict[str, Any] {
    if db in (":memory:", "inmemory") {
        return {"metadata_store": {"provider": "inmemory"}};
    }
    if db.startswith(("postgres://", "postgresql://")) {
        return {"metadata_store": {"provider": "postgres", "dsn": db}};
    }
    if db.startswith("sqlite://") {
        return {"metadata_store": {"provider": "sqlite", "dsn": db}};
    }
    path = Path(db).expanduser();
    path.parent.mkdir(parents=True, exist_ok=True);
    return {"metadata_store": {"provider": "sqlite", "dsn": f"sqlite:///{path}"}};
}

def embedding_provider -> str {
    return env("MEMU_EMBED_PROVIDER") or env("MEMU_LLM_PROVIDER") or "openai";
}

def embedding_profile -> dict[str, Any] {
    profile: dict[str, Any] = {"provider": embedding_provider()};
    for (key, var) in (
        ("embed_model", "MEMU_EMBED_MODEL"),
        ("base_url", "MEMU_BASE_URL"),
        ("api_key", "MEMU_API_KEY"),
    ) {
        if (value := env(var)) {
            profile[key] = value;
        }
    }
    if (value := env("MEMU_EMBED_BATCH_SIZE")) {
        try {
            batch_size = int(value);
        } except ValueError as exc {
            raise ConfigError("MEMU_EMBED_BATCH_SIZE", "must be a positive integer") from exc;
        }
        if batch_size < 1 {
            raise ConfigError("MEMU_EMBED_BATCH_SIZE", "must be a positive integer");
        }
        profile["embed_batch_size"] = batch_size;
    }
    return profile;
}

glob QueryKind = Literal["short", "long", "extracted"],
     LONG_QUERY_CHARS = 200,
     _CLOUD_RETRIEVAL_MIN_SCORES: dict[QueryKind, float] = {
         "short": 0.55,
         "long": 0.6,
         "extracted": 0.58,
     };

def retrieval_min_score(kind: QueryKind) -> float | None {
    mode = memory_mode();
    name = f"MEMU_{mode.upper()}_RETRIEVE_MIN_SCORE_{kind.upper()}";
    value = env(name);
    if value is None {
        return _CLOUD_RETRIEVAL_MIN_SCORES[kind] if mode == "cloud" else None;
    }
    try {
        score = float(value);
    } except ValueError as exc {
        raise ConfigError(name, "must be a finite number between -1 and 1") from exc;
    }
    if not math.isfinite(score) or not -1 <= score <= 1 {
        raise ConfigError(name, "must be a finite number between -1 and 1");
    }
    return score;
}

glob MemoryMode = Literal["local", "cloud"];

def memory_mode -> MemoryMode {
    value = (env("MEMU_MEMORY_MODE", "local") or "local").strip().lower();
    if value == "local" {
        return "local";
    }
    if value == "cloud" {
        return "cloud";
    }
    raise ConfigError("MEMU_MEMORY_MODE", "must be either 'local' or 'cloud'");
}

def cloud_base_url -> str {
    DEFAULT_CLOUD_BASE_URL = importlib.import_module("memu.cloud").DEFAULT_CLOUD_BASE_URL;
    return env("MEMU_CLOUD_BASE_URL", DEFAULT_CLOUD_BASE_URL) or DEFAULT_CLOUD_BASE_URL;
}

def cloud_api_key -> str {
    value = env("MEMU_CLOUD_API_KEY");
    if not value {
        raise ConfigError(
            "MEMU_CLOUD_API_KEY",
            f"is required in cloud mode. Add it to {CONFIG_ENV} (or export it)",
        );
    }
    return value;
}

def build_agentic_memory_backend_from_env(
    *, local_database: str | None = None, local_embedding_profile: Optional[dict[str, Any]] = None
) -> any {
    if memory_mode() == "cloud" {
        CloudMemoryClient = importlib.import_module("memu.cloud").CloudMemoryClient;
        return CloudMemoryClient(base_url=cloud_base_url(), api_key=cloud_api_key()) as any;
    }
    MemoryService = importlib.import_module("memu.app").MemoryService;
    resolved_database = database_config(
        local_database if local_database is not None else require("MEMU_DB")
    );
    resolved_embedding = local_embedding_profile
        if local_embedding_profile is not None
        else embedding_profile();
    return MemoryService(
        embedding_profiles={"default": resolved_embedding}, database_config=resolved_database
    ) as any;
}

def build_service_from_env -> Any {
    MemoryService = importlib.import_module("memu.app").MemoryService;
    return MemoryService(
        embedding_profiles={"default": embedding_profile()},
        database_config=database_config(require("MEMU_DB")),
    );
}
