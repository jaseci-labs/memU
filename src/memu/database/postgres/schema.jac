import builtins;
import from typing { Type }
import from dataclasses { dataclass }
import from typing { Any }
import from pydantic { BaseModel }
glob msg: any,
     SQLModel: any,
     MetaData: any,
     Vector: any;

with entry {
    try {
        import from sqlmodel { SQLModel as SQLModel_ }
        SQLModel = SQLModel_;
    } except ImportError as exc {
        raise ImportError("sqlmodel is required for Postgres storage support") from exc;
    }
    try {
        import from sqlalchemy { MetaData as MetaData_ }
        MetaData = MetaData_;
    } except ImportError as exc {
        raise ImportError("sqlalchemy is required for Postgres storage support") from exc;
    }
    try {
        import from pgvector.sqlalchemy { VECTOR as Vector_ }
        Vector = Vector_;
    } except ImportError as exc {
        raise ImportError("pgvector is required for Postgres vector support") from exc;
    }
}

glob DefaultScope = DefaultUserModel;

@dataclass
class SQLAModels {
    has Base: Type[Any],
        Resource: Type[Any],
        RecallFile: Type[Any],
        RecallFileSegment: Type[Any];
}

glob _MODEL_CACHE: dict[Type[Any], SQLAModels] = {};

def require_sqlalchemy {
    return None;
}

def get_sqlalchemy_models(*, scope_model: Type[BaseModel] | None = None) -> SQLAModels {
    require_sqlalchemy();
    scope = scope_model or DefaultScope;
    cache_key = scope;
    cached = _MODEL_CACHE.get(cache_key);
    if cached {
        return cached;
    }
    metadata_obj = MetaData();
    resource_model = build_table_model(
        scope, ResourceModel, tablename="resources", metadata=metadata_obj
    );
    recall_file_model = build_table_model(
        scope, RecallFileModel, tablename="recall_files", metadata=metadata_obj
    );
    recall_file_segment_model = build_table_model(
        scope, RecallFileSegmentModel, tablename="recall_file_segments", metadata=metadata_obj
    );
    Base = builtins.type("Base", (SQLModel,), {"__abstract__": True, "metadata": metadata_obj});
    models = SQLAModels(
        Base=Base,
        Resource=resource_model,
        RecallFile=recall_file_model,
        RecallFileSegment=recall_file_segment_model,
    );
    _MODEL_CACHE[cache_key] = models;
    return models;
}

def get_metadata(scope_model: Type[BaseModel] | None = None) -> MetaData {
    import from typing { cast }
    return cast(MetaData, get_sqlalchemy_models(scope_model=scope_model).Base.metadata);
}

glob __all__ = [
    "SQLAModels",
    "Vector",
    "get_metadata",
    "get_sqlalchemy_models",
    "require_sqlalchemy",
];
