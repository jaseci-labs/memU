impl default_embedding_model(provider: str) -> str | None {
    return EMBEDDING_PROVIDER_DEFAULTS.get(provider.lower());
}
