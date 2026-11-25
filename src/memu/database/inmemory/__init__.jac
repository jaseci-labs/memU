import from typing { Type }
import from pydantic { BaseModel }
def build_inmemory_database(
    *, config: DatabaseConfig, user_model: Type[BaseModel]
) -> InMemoryStore;
glob __all__ = ["build_inmemory_database"];
