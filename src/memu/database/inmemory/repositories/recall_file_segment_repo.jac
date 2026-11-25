import from typing { Type }
import uuid;
import from collections.abc { Mapping }
import from typing { Any }

class InMemoryFileSegmentRepository(RecallFileSegmentRepo) {
    has recall_file_segment_model: Type[RecallFileSegment],
        _state: InMemoryState;
    def init(*, state: InMemoryState, recall_file_segment_model: Type[RecallFileSegment]);
    def list_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment];
    def list_segments_for_file(recall_file_id: str) -> list[RecallFileSegment];
    def create_segment(
        *,
        recall_file_id: str,
        text: str,
        embedding: list[float] | None,
        user_data: dict[str, Any],
        track: str = "memory",
    ) -> RecallFileSegment;
    def delete_segment(segment_id: str);
    def delete_segments_for_file(recall_file_id: str) -> list[RecallFileSegment];
    def clear_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment];
    def load_existing;
}

glob __all__ = ["InMemoryFileSegmentRepository"];
