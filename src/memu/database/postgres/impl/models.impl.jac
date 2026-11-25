impl TZDateTime.init(timezone: bool = True, **kw: Any) {
    super.init(timezone=timezone, **kw);
}

impl _normalize_table_args(table_args: Any) -> tuple[list[Any], dict[str, Any]] {
    if table_args is None {
        return ([], {});
    }
    if isinstance(table_args, dict) {
        return ([], dict(table_args));
    }
    if not isinstance(table_args, tuple) {
        return ([table_args], {});
    }
    args = list(table_args);
    kwargs: dict[str, Any] = {};
    if args and isinstance(args[-1], dict) {
        kwargs = dict(args.pop());
    }
    return (args, kwargs);
}

impl _merge_models(
    user_model: Type[BaseModel],
    core_model: Type[SQLModel],
    *,
    name_suffix: str,
    base_attrs: dict[str, Any],
) -> Type[SQLModel] {
    overlap = set(user_model.model_fields) & set(core_model.model_fields);
    if overlap {
        raise TypeError(f"Scope fields conflict with core model fields: {sorted(overlap)}");
    }
    return builtins.type(
        f"{user_model.__name__}{core_model.__name__}{name_suffix}",
        (user_model, core_model),
        base_attrs,
    );
}

impl build_table_model(
    user_model: Type[BaseModel],
    core_model: Type[SQLModel],
    *,
    tablename: str,
    metadata: MetaData | None = None,
    extra_table_args: Optional[tuple[Any, ...]] = None,
    unique_with_scope: Optional[list[str]] = None,
) -> Type[SQLModel] {
    overlap = set(user_model.model_fields) & set(core_model.model_fields);
    if overlap {
        raise TypeError(f"Scope fields conflict with core model fields: {sorted(overlap)}");
    }
    scope_fields = list(user_model.model_fields.keys());
    (base_table_args, table_kwargs) = _normalize_table_args(
        getattr(core_model, "__table_args__", None)
    );
    table_args = list(base_table_args);
    if extra_table_args {
        table_args.extend(extra_table_args);
    }
    if scope_fields {
        table_args.append(Index(f"ix_{tablename}__scope", *scope_fields));
    }
    if unique_with_scope {
        unique_cols = [*unique_with_scope, *scope_fields];
        table_args.append(Index(f"ix_{tablename}__unique_scoped", *unique_cols, unique=True));
    }
    base_attrs: dict[str, Any] = {"__module__": core_model.__module__, "__tablename__": tablename};
    if metadata is not None {
        base_attrs["metadata"] = metadata;
    }
    if table_args or table_kwargs {
        if table_kwargs {
            base_attrs["__table_args__"] = (*table_args, table_kwargs);
        } else {
            base_attrs["__table_args__"] = tuple(table_args);
        }
    }
    base = _merge_models(user_model, core_model, name_suffix="Base", base_attrs=base_attrs);
    table_attrs: dict[str, Any] = {"__module__": core_model.__module__};
    return builtins.type(
        f"{user_model.__name__}{core_model.__name__}Table", (base,), table_attrs, table=True
    );
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
