import from typing { Type }
import from pydantic { BaseModel }

class InMemoryResource(Resource) {}

class InMemoryRecallFile(RecallFile) {}

class InMemoryFileSegment(RecallFileSegment) {}

def build_inmemory_models(
    user_model: Type[BaseModel]
) -> tuple[Type[InMemoryResource], Type[InMemoryRecallFile], Type[InMemoryFileSegment]] {
    resource_model = merge_scope_model(user_model, InMemoryResource, name_suffix="Resource");
    recall_file_model = merge_scope_model(user_model, InMemoryRecallFile, name_suffix="RecallFile");
    recall_file_segment_model = merge_scope_model(
        user_model, InMemoryFileSegment, name_suffix="RecallFileSegment"
    );
    return (resource_model, recall_file_model, recall_file_segment_model);
}

glob __all__ = [
    "InMemoryFileSegment",
    "InMemoryRecallFile",
    "InMemoryResource",
    "build_inmemory_models",
];
