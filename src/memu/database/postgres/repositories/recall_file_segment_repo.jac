import operator;
import from typing { Type, Optional }
import from collections.abc { Mapping }
import from typing { Any }

class PostgresRecallFileSegmentRepo(PostgresRepoBase, RecallFileSegmentRepo) {
    has _recall_file_segment_model: Type[RecallFileSegment];
    def init(
        *,
        state: DatabaseState,
        recall_file_segment_model: Type[RecallFileSegment],
        sqla_models: Any,
        sessions: SessionManager,
        scope_fields: list[str],
        use_vector: bool = True,
    );
    def _row_to_record(row: Any) -> RecallFileSegment;
    def _cache_segment(row: Any) -> RecallFileSegment;
    def list_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment];
    def list_segments_for_file(recall_file_id: str) -> list[RecallFileSegment];
    def vector_search_segments(
        query_vec: list[float], top_k: int, where: Mapping[str, Any] | None = None
    ) -> list[tuple[RecallFileSegment, float]];
    def create_segment(
        *,
        recall_file_id: str,
        text: str,
        embedding: Optional[list[float]],
        user_data: dict[str, Any],
        track: str = "memory",
    ) -> RecallFileSegment;
    def delete_segment(segment_id: str);
    def delete_segments_for_file(recall_file_id: str) -> list[RecallFileSegment];
    def clear_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment];
    def load_existing;
}

glob __all__ = ["PostgresRecallFileSegmentRepo"];
