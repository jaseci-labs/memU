import from collections.abc { Mapping }
import from typing { Any, Protocol, runtime_checkable, Optional }

@runtime_checkable
class RecallFileSegmentRepo(Protocol) {
    has segments: list[RecallFileSegment];
    def list_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment] abst;
    def vector_search_segments(
        query_vec: list[float], top_k: int, where: Mapping[str, Any] | None = None
    ) -> list[tuple[RecallFileSegment, float]];
    def list_segments_for_file(recall_file_id: str) -> list[RecallFileSegment] abst;
    def create_segment(
        *,
        recall_file_id: str,
        text: str,
        embedding: Optional[list[float]],
        user_data: dict[str, Any],
        track: str = "memory",
    ) -> RecallFileSegment abst;
    def delete_segment(segment_id: str) abst;
    def delete_segments_for_file(recall_file_id: str) -> list[RecallFileSegment] abst;
    def clear_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment] abst;
    def load_existing abst;
}
