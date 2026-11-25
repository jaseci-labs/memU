import from typing { Type }
import importlib;
import from pydantic { BaseModel }
def build_database(*, config: DatabaseConfig, user_model: Type[BaseModel]) -> Database;
