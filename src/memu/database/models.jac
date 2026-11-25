import from typing { Type, Optional }
import builtins;
import uuid;
import from datetime { datetime }
import from typing { TypeVar }
import pendulum;
import from pydantic { BaseModel, ConfigDict, Field }

class BaseRecord(BaseModel) {
    has id: str = Field(default_factory=lambda -> any { str(uuid.uuid4()) }),
        created_at: datetime = Field(default_factory=lambda -> any { pendulum.now("UTC") }),
        updated_at: datetime = Field(default_factory=lambda -> any { pendulum.now("UTC") });
}

class Resource(BaseRecord) {
    has url: str,
        local_path: str,
        caption: str | None = None,
        embedding: Optional[list[float]] = None,
        track: str | None = None;
}

class RecallFile(BaseRecord) {
    has name: str,
        track: str = "memory",
        description: str,
        embedding: Optional[list[float]] = None,
        content: str | None = None;
}

class RecallFileSegment(BaseRecord) {
    has recall_file_id: str,
        track: str = "memory",
        text: str,
        embedding: Optional[list[float]] = None;
}

glob TBaseRecord: any;

with entry {
    TBaseRecord = TypeVar("TBaseRecord", bound=BaseRecord);
}

def merge_scope_model(
    user_model: Type[BaseModel], core_model: Type[TBaseRecord], *, name_suffix: str
) -> Type[TBaseRecord];
def build_scoped_models(
    user_model: Type[BaseModel]
) -> tuple[Type[Resource], Type[RecallFile], Type[RecallFileSegment]];
glob __all__ = [
    "BaseRecord",
    "RecallFile",
    "RecallFileSegment",
    "Resource",
    "build_scoped_models",
    "merge_scope_model",
];
