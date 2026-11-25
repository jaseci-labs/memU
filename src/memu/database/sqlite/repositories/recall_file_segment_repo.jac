import operator;
import from typing { Type, Optional }
import logging;
import from collections.abc { Mapping }
import from typing { Any }
import from sqlmodel { delete, select }
glob logger = logging.getLogger(__name__);

class SQLiteRecallFileSegmentRepo(SQLiteRepoBase, RecallFileSegmentRepo) {
    has _record_model: Type[RecallFileSegment],
        _recall_file_segment_model: Type[Any];
    def init(
        *,
        state: DatabaseState,
        recall_file_segment_model: Type[Any],
        sqla_models: SQLiteSQLAModels,
        sessions: SQLiteSessionManager,
        scope_fields: list[str],
        record_model: Type[RecallFileSegment] = RecallFileSegment,
    );
    def _row_to_record(row: Any) -> RecallFileSegment;
    def list_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment];
    def list_segments_for_file(recall_file_id: str) -> list[RecallFileSegment];
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

glob __all__ = ["SQLiteRecallFileSegmentRepo"];
