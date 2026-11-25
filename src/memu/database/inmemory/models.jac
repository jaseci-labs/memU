import from typing { Type }
import from pydantic { BaseModel }

class InMemoryResource(Resource) {}

class InMemoryRecallFile(RecallFile) {}

class InMemoryFileSegment(RecallFileSegment) {}

def build_inmemory_models(
    user_model: Type[BaseModel]
) -> tuple[Type[InMemoryResource], Type[InMemoryRecallFile], Type[InMemoryFileSegment]];
glob __all__ = [
    "InMemoryFileSegment",
    "InMemoryRecallFile",
    "InMemoryResource",
    "build_inmemory_models",
];
