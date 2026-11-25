impl MemoryService.init(
    *,
    database_config: DatabaseConfig | dict[str, Any] | None = None,
    embedding_profiles: EmbeddingProfilesConfig | dict[str, Any] | None = None,
    progressive_retrieve_config: ProgressiveRetrieveConfig | dict[str, Any] | None = None,
    user_config: UserConfig | dict[str, Any] | None = None,
) {
    self.user_config = self._validate_config(user_config, UserConfig);
    self.user_model = self.user_config.model;
    self.database_config = self._validate_config(database_config, DatabaseConfig);
    self.progressive_retrieve_config = self._validate_config(
        progressive_retrieve_config, ProgressiveRetrieveConfig
    );
    self.embedding_profiles = self._validate_config(
        embedding_profiles, EmbeddingProfilesConfig
    ).profiles;
    self.database = build_database(config=self.database_config, user_model=self.user_model);
    self._embedding_pool = ClientPool(
        profiles=self.embedding_profiles, builder=build_embedding_client, label="embedding"
    );
}

impl MemoryService._get_database -> Database {
    return self.database;
}

impl MemoryService._get_embedding_client(profile: str | None = None) -> Any {
    return self._embedding_pool.get(profile);
}

impl MemoryService._normalize_where(where: Mapping[str, Any] | None) -> dict[str, Any] {
    if not where {
        return {};
    }
    valid_fields = set(getattr(self.user_model, "model_fields", {}).keys());
    cleaned: dict[str, Any] = {};
    for (raw_key, value) in where.items() {
        if value is None {
            continue;
        }
        field = raw_key.split("__", 1)[0];
        if field not in valid_fields {
            raise ValueError(f"Unknown filter field '{field}' for current user scope");
        }
        cleaned[raw_key] = value;
    }
    return cleaned;
}

impl MemoryService._model_dump_without_embeddings(`obj: BaseModel) -> dict[str, Any] {
    return `obj.model_dump(exclude={"embedding"});
}

impl MemoryService._validate_config(
    config: Mapping[str, Any] | BaseModel | None, model_type: Type[TConfigModel]
) -> TConfigModel {
    if isinstance(config, model_type) {
        return config;
    }
    if config is None {
        return model_type();
    }
    return model_type.model_validate(config);
}
