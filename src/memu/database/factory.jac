import from typing { Type }
import from typing { TYPE_CHECKING }
import from pydantic { BaseModel }
def build_database(*, config: DatabaseConfig, user_model: Type[BaseModel]) -> Database;
