impl build_sqlite_database(*, config: DatabaseConfig, user_model: Type[BaseModel]) -> SQLiteStore {
    dsn = config.metadata_store.dsn;
    if not dsn {
        dsn = "sqlite:///memu.db";
    }
    return SQLiteStore(dsn=dsn, scope_model=user_model);
}
