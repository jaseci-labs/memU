import from typing { Type }
import from pydantic { BaseModel }
def build_postgres_database(
    *, config: DatabaseConfig, user_model: Type[BaseModel]
) -> PostgresStore;
glob __all__ = ["build_postgres_database"];
