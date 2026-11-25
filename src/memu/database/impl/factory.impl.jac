impl build_database(*, config: DatabaseConfig, user_model: Type[BaseModel]) -> Database {
    provider = config.metadata_store.provider;
    if provider == "inmemory" {
        return build_inmemory_database(config=config, user_model=user_model);
    } elif provider == "postgres" {
        postgres = importlib.import_module("memu.database.postgres");
        return postgres.build_postgres_database(config=config, user_model=user_model);
    } elif provider == "sqlite" {
        build_sqlite_database = importlib.import_module(
            "memu.database.sqlite"
        ).build_sqlite_database;
        return build_sqlite_database(config=config, user_model=user_model);
    } else {
        raise ValueError(f"Unsupported metadata_store provider: {provider}");
    }
}
