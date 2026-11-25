impl TZDateTime.init(timezone: bool = True, **kw: Any) {
    super.init(timezone=timezone, **kw);
}

impl build_scoped_models(
    user_model: Type[BaseModel]
) -> tuple[Type[SQLModel], Type[SQLModel], Type[SQLModel]] {
    resource_model = build_table_model(user_model, ResourceModel, tablename="resources");
    recall_file_model = build_table_model(
        user_model, RecallFileModel, tablename="recall_files", unique_with_scope=["name"]
    );
    recall_file_segment_model = build_table_model(
        user_model, RecallFileSegmentModel, tablename="recall_file_segments"
    );
    return (resource_model, recall_file_model, recall_file_segment_model);
}
