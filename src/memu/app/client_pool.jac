import from collections.abc { Callable, Mapping }
import from typing { Generic, TypeVar }
glob TConfig = TypeVar("TConfig"),
     TClient = TypeVar("TClient"),
     _PoolBase: any = Generic[TConfig, TClient];

class ClientPool(_PoolBase) {
    has _cache: dict[str, TClient],
        _default_profile: str,
        _label: str,
        _builder: Callable[[TConfig], TClient],
        _profiles: Mapping[str, TConfig];
    def init(
        *,
        profiles: Mapping[str, TConfig],
        builder: Callable[[TConfig], TClient],
        label: str,
        default_profile: str = "default",
    );
    def config(profile: str | None = None) -> TConfig | None;
    def get(profile: str | None = None) -> TClient;
}

glob __all__ = ["ClientPool"];
