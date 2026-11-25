impl merge_scope_model(
    user_model: Type[BaseModel], core_model: Type[TBaseRecord], *, name_suffix: str
) -> Type[TBaseRecord] {
    overlap = set(user_model.model_fields) & set(core_model.model_fields);
    if overlap {
        raise TypeError(f"Scope fields conflict with core model fields: {sorted(overlap)}");
    }
    return builtins.type(
        f"{user_model.__name__}{core_model.__name__}{name_suffix}",
        (user_model, core_model),
        {"model_config": ConfigDict(extra="allow")},
    );
}

impl build_scoped_models(
    user_model: Type[BaseModel]
) -> tuple[Type[Resource], Type[RecallFile], Type[RecallFileSegment]] {
    resource_model = merge_scope_model(user_model, Resource, name_suffix="Resource");
    recall_file_model = merge_scope_model(user_model, RecallFile, name_suffix="RecallFile");
    recall_file_segment_model = merge_scope_model(
        user_model, RecallFileSegment, name_suffix="RecallFileSegment"
    );
    return (resource_model, recall_file_model, recall_file_segment_model);
}
