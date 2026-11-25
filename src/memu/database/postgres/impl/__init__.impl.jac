impl build_postgres_database(
    *, config: DatabaseConfig, user_model: Type[BaseModel]
) -> PostgresStore {
    dsn = config.metadata_store.dsn;
    if not dsn {
        raise ValueError("Postgres metadata_store requires a DSN");
    }
    vector_provider = config.vector_index.provider if config.vector_index else None;
    sqla_models: SQLAModels = get_sqlalchemy_models(scope_model=user_model);
    return PostgresStore(
        dsn=dsn,
        ddl_mode=config.metadata_store.ddl_mode,
        vector_provider=vector_provider,
        scope_model=user_model,
        resource_model=sqla_models.Resource,
        recall_file_model=sqla_models.RecallFile,
        sqla_models=sqla_models,
    );
}
