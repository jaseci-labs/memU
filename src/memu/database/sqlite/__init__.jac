import from typing { Type }
import from pydantic { BaseModel }
def build_sqlite_database(*, config: DatabaseConfig, user_model: Type[BaseModel]) -> SQLiteStore;
glob __all__ = ["SQLiteStore", "build_sqlite_database"];
