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
def get_sqlite_sqlalchemy_models(*, scope_model: Type[BaseModel] | None = None) -> SQLiteSQLAModels;
def get_sqlite_metadata(scope_model: Type[BaseModel] | None = None) -> MetaData;
glob __all__ = ["SQLiteSQLAModels", "get_sqlite_metadata", "get_sqlite_sqlalchemy_models"];
