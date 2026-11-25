import from typing { Type }
import from collections.abc { Iterator }
import from contextlib { contextmanager }
import from typing { Any }
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
    );
    @contextmanager
    def atomic -> Iterator[None];
    @contextmanager
    def snapshot -> Iterator[None];
    def close;
}
