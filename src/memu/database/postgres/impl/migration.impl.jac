impl _escape_for_config_parser(value: str) -> str {
    return _UNESCAPED_CONFIGPARSER_PERCENT.sub("%%", value);
}

impl make_alembic_config(*, dsn: str, scope_model: Type[Any]) -> AlembicConfig {
    cfg = AlembicConfig();
    cfg.set_main_option("script_location", str(Path(__file__).with_name("migrations")));
    cfg.set_main_option("sqlalchemy.url", _escape_for_config_parser(dsn));
    cfg.attributes["scope_model"] = scope_model;
    return cfg;
}

impl run_migrations(*, dsn: str, scope_model: Type[Any], ddl_mode: DDLMode = "create") {
    import from memu.database.postgres.schema { get_metadata }
    if ddl_mode == "create" {
        cfg = make_alembic_config(dsn=dsn, scope_model=scope_model);
        command.upgrade(cfg, "head");
        logger.info("Database migrated to head");
    } elif ddl_mode == "validate" {
        metadata = get_metadata(scope_model);
        engine = create_engine(dsn);
        try {
            inspector = inspect(engine);
            existing_tables = set(inspector.get_table_names());
            expected_tables = set(metadata.tables.keys());
            missing_tables = expected_tables - existing_tables;
            if missing_tables {
                msg = f"Database schema validation failed. Missing tables: {sorted(missing_tables)}";
                raise RuntimeError(msg);
            }
            logger.info("Database schema validated successfully");
        } finally {
            engine.dispose();
        }
    }
}
