import from typing { Type, Optional }
import uuid;
import from collections.abc { Mapping }
import from typing { Any }

class InMemoryFileSegmentRepository(RecallFileSegmentRepo) {
    has recall_file_segment_model: Type[RecallFileSegment],
        _state: InMemoryState;

    def init(*, state: InMemoryState, recall_file_segment_model: Type[RecallFileSegment]) {
        self._state = state;
        self.recall_file_segment_model = recall_file_segment_model;
        self.segments = self._state.segments;
    }

    def list_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment] {
        return list(self.segments)
            if not where
            else ([seg for seg in self.segments if matches_where(seg, where)]);
    }

    def list_segments_for_file(recall_file_id: str) -> list[RecallFileSegment] {
        return [seg for seg in self.segments if seg.recall_file_id == recall_file_id];
    }

    def create_segment(
        *,
        recall_file_id: str,
        text: str,
        embedding: Optional[list[float]],
        user_data: dict[str, Any],
        track: str = "memory",
    ) -> RecallFileSegment {
        seg = self.recall_file_segment_model(
            id=str(uuid.uuid4()),
            recall_file_id=recall_file_id,
            track=track,
            text=text,
            embedding=embedding,
            **user_data,
        );
        self.segments.append(seg);
        return seg;
    }

    def delete_segment(segment_id: str) {
        self.segments[:] = [seg for seg in self.segments if seg.id != segment_id];
    }

    def delete_segments_for_file(recall_file_id: str) -> list[RecallFileSegment] {
        removed = [seg for seg in self.segments if seg.recall_file_id == recall_file_id];
        self.segments[:] = [seg for seg in self.segments if seg.recall_file_id != recall_file_id];
        return removed;
    }

    def clear_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment] {
        if not where {
            removed = list(self.segments);
            self.segments.clear();
            return removed;
        }
        removed = [seg for seg in self.segments if matches_where(seg, where)];
        removed_ids = {seg.id for seg in removed};
        self.segments[:] = [seg for seg in self.segments if seg.id not in removed_ids];
        return removed;
    }

    def load_existing {
        return None;
    }
}

glob __all__ = ["InMemoryFileSegmentRepository"];
