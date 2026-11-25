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
        msg = "sqlmodel is required for Postgres storage support";
        raise ImportError(msg) from exc;
    }
    try {
        import from sqlalchemy { MetaData as MetaData_ }
        MetaData = MetaData_;
    } except ImportError as exc {
        msg = "sqlalchemy is required for Postgres storage support";
        raise ImportError(msg) from exc;
    }
    try {
        import from pgvector.sqlalchemy { VECTOR as Vector_ }
        Vector = Vector_;
    } except ImportError as exc {
        msg = "pgvector is required for Postgres vector support";
        raise ImportError(msg) from exc;
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
def require_sqlalchemy;
def get_sqlalchemy_models(*, scope_model: Type[BaseModel] | None = None) -> SQLAModels;
def get_metadata(scope_model: Type[BaseModel] | None = None) -> MetaData;
glob __all__ = [
    "SQLAModels",
    "Vector",
    "get_metadata",
    "get_sqlalchemy_models",
    "require_sqlalchemy",
];
