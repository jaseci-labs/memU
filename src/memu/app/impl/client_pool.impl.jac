impl ClientPool.init(
    *,
    profiles: Mapping[str, TConfig],
    builder: Callable[[TConfig], TClient],
    label: str,
    default_profile: str = "default",
) {
    self._profiles = profiles;
    self._builder = builder;
    self._label = label;
    self._default_profile = default_profile;
    self._cache = {};
}

impl ClientPool.config(profile: str | None = None) -> TConfig | None {
    return self._profiles.get(profile or self._default_profile);
}

impl ClientPool.get(profile: str | None = None) -> TClient {
    name = profile or self._default_profile;
    cached = self._cache.get(name);
    if cached is not None {
        return cached;
    }
    cfg = self._profiles.get(name);
    if cfg is None {
        raise KeyError(f"Unknown {self._label} profile '{name}'");
    }
    client = self._builder(cfg);
    self._cache[name] = client;
    return client;
}
