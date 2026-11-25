import from typing { Type, Any }
import from collections.abc { Iterator }
import from contextlib { contextmanager }
import from pydantic { BaseModel }

class InMemoryStore(Database) {
    has state: any,
        scope_model: any;

    def init(
        *,
        scope_model: Type[BaseModel] | None = None,
        resource_model: Type[Any] | None = None,
        recall_file_model: Type[Any] | None = None,
        recall_file_segment_model: Type[Any] | None = None,
        state: InMemoryState | None = None,
    ) {
        self.scope_model = scope_model or BaseModel;
        (
            default_resource_model,
            default_recall_file_model,
            default_recall_file_segment_model,
        ) = build_inmemory_models(self.scope_model);
        self.state = state or InMemoryState();
        self.resources = self.state.resources;
        self.recall_files = self.state.recall_files;
        self.segments = self.state.segments;
        resource_model = resource_model or default_resource_model or Resource;
        recall_file_model = recall_file_model or default_recall_file_model or RecallFile;
        recall_file_segment_model = recall_file_segment_model
            or default_recall_file_segment_model
            or RecallFileSegment;
        self.resource_repo = InMemoryResourceRepository(
            state=self.state, resource_model=resource_model
        );
        self.recall_file_repo = InMemoryRecallFileRepository(
            state=self.state, recall_file_model=recall_file_model
        );
        self.recall_file_segment_repo = InMemoryFileSegmentRepository(
            state=self.state, recall_file_segment_model=recall_file_segment_model
        );
    }

    @contextmanager
    def atomic -> Iterator[None] {
        with preserve_state(self.state) {
            yield None;
        }
    }

    @contextmanager
    def snapshot -> Iterator[None] {
        with self.state.lock {
            yield None;
        }
    }

    def close {
        return None;
    }
}
