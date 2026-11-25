impl build_database(*, config: DatabaseConfig, user_model: Type[BaseModel]) -> Database {
    provider = config.metadata_store.provider;
    if provider == "inmemory" {
        return build_inmemory_database(config=config, user_model=user_model);
    } elif provider == "postgres" {
        import from memu.database.postgres { build_postgres_database }
        return build_postgres_database(config=config, user_model=user_model);
    } elif provider == "sqlite" {
        import from memu.database.sqlite { build_sqlite_database }
        return build_sqlite_database(config=config, user_model=user_model);
    } else {
        msg = f"Unsupported metadata_store provider: {provider}";
        raise ValueError(msg);
    }
}
