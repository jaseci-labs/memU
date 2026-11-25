impl build_inmemory_database(
    *, config: DatabaseConfig, user_model: Type[BaseModel]
) -> InMemoryStore {
    (resource_model, recall_file_model, recall_file_segment_model) = build_inmemory_models(
        user_model
    );
    return InMemoryStore(
        scope_model=user_model,
        resource_model=resource_model,
        recall_file_model=recall_file_model,
        recall_file_segment_model=recall_file_segment_model,
    );
}
