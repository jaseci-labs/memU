import builtins;
import from typing { Type }
import from dataclasses { dataclass }
import from typing { Any }
import from pydantic { BaseModel }
import from sqlalchemy { MetaData }
import from sqlmodel { SQLModel }

@dataclass
class SQLiteSQLAModels {
    has Base: Type[Any],
        Resource: Type[Any],
        RecallFile: Type[Any],
        RecallFileSegment: Type[Any];
}

glob _MODEL_CACHE: dict[Type[Any], SQLiteSQLAModels] = {};

def get_sqlite_sqlalchemy_models(
    *, scope_model: Type[BaseModel] | None = None
) -> SQLiteSQLAModels {
    scope = scope_model or BaseModel;
    cache_key = scope;
    cached = _MODEL_CACHE.get(cache_key);
    if cached {
        return cached;
    }
    metadata_obj = MetaData();
    resource_model = build_table_model(
        scope, SQLiteResourceModel, tablename="memu_resources", metadata=metadata_obj
    );
    recall_file_model = build_table_model(
        scope, SQLiteRecallFileModel, tablename="memu_recall_files", metadata=metadata_obj
    );
    recall_file_segment_model = build_table_model(
        scope,
        SQLiteRecallFileSegmentModel,
        tablename="memu_recall_file_segments",
        metadata=metadata_obj,
    );
    SQLiteBase = builtins.type(
        "SQLiteBase", (SQLModel,), {"__abstract__": True, "metadata": metadata_obj}
    );
    models = SQLiteSQLAModels(
        Base=SQLiteBase,
        Resource=resource_model,
        RecallFile=recall_file_model,
        RecallFileSegment=recall_file_segment_model,
    );
    _MODEL_CACHE[cache_key] = models;
    return models;
}

def get_sqlite_metadata(scope_model: Type[BaseModel] | None = None) -> MetaData {
    import from typing { cast }
    return cast(MetaData, get_sqlite_sqlalchemy_models(scope_model=scope_model).Base.metadata);
}

glob __all__ = ["SQLiteSQLAModels", "get_sqlite_metadata", "get_sqlite_sqlalchemy_models"];
