import operator;
import from typing { Type, Optional, Any }
import logging;
import from collections.abc { Mapping }
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
    ) {
        super.init(
            state=state, sqla_models=sqla_models, sessions=sessions, scope_fields=scope_fields
        );
        self._recall_file_segment_model = recall_file_segment_model;
        self._record_model = record_model;
        self.segments = self._state.segments;
    }

    def _row_to_record(row: Any) -> RecallFileSegment {
        return self._record_model(
            id=row.id,
            recall_file_id=row.recall_file_id,
            track=row.track,
            text=row.text,
            embedding=self._normalize_embedding(row.embedding),
            created_at=row.created_at,
            updated_at=row.updated_at,
            **self._scope_kwargs_from(row),
        );
    }

    def list_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment] {
        with self._sessions.session() as session {
            stmt = select(self._recall_file_segment_model);
            filters = self._build_filters(self._recall_file_segment_model, where);
            if filters {
                stmt = stmt.where(*filters);
            }
            rows = session.exec(stmt).all();
        }
        cached_ids = {segment.id for segment in self.segments};
        result: list[RecallFileSegment] = [];
        for row in rows {
            seg = self._row_to_record(row);
            result.append(seg);
            if seg.id not in cached_ids {
                self.segments.append(seg);
                cached_ids.add(seg.id);
            }
        }
        return result;
    }

    def list_segments_for_file(recall_file_id: str) -> list[RecallFileSegment] {
        return self.list_segments({"recall_file_id": recall_file_id});
    }

    def create_segment(
        *,
        recall_file_id: str,
        text: str,
        embedding: Optional[list[float]],
        user_data: dict[str, Any],
        track: str = "memory",
    ) -> RecallFileSegment {
        now = self._now();
        with self._sessions.session() as session {
            row = self._recall_file_segment_model(
                recall_file_id=recall_file_id,
                track=track,
                text=text,
                embedding=self._prepare_embedding(embedding),
                created_at=now,
                updated_at=now,
                **user_data,
            );
            session.add(row);
            session.commit();
            session.refresh(row);
            seg = self._row_to_record(row);
        }
        self.segments.append(seg);
        return seg;
    }

    def delete_segment(segment_id: str) {
        with self._sessions.session() as session {
            session.exec(
                delete(self._recall_file_segment_model).where(
                    operator.eq(self._recall_file_segment_model.id, segment_id)
                ),
            );
            session.commit();
        }
        self.segments[:] = [seg for seg in self.segments if seg.id != segment_id];
    }

    def delete_segments_for_file(recall_file_id: str) -> list[RecallFileSegment] {
        removed = self.list_segments_for_file(recall_file_id);
        if not removed {
            return [];
        }
        with self._sessions.session() as session {
            session.exec(
                delete(self._recall_file_segment_model).where(
                    operator.eq(self._recall_file_segment_model.recall_file_id, recall_file_id)
                ),
            );
            session.commit();
        }
        self.segments[:] = [seg for seg in self.segments if seg.recall_file_id != recall_file_id];
        return removed;
    }

    def clear_segments(where: Mapping[str, Any] | None = None) -> list[RecallFileSegment] {
        removed = self.list_segments(where);
        if not removed {
            return [];
        }
        filters = self._build_filters(self._recall_file_segment_model, where);
        with self._sessions.session() as session {
            del_stmt = delete(self._recall_file_segment_model);
            if filters {
                del_stmt = del_stmt.where(*filters);
            }
            session.exec(del_stmt);
            session.commit();
        }
        removed_ids = {seg.id for seg in removed};
        self.segments[:] = [seg for seg in self.segments if seg.id not in removed_ids];
        return removed;
    }

    def load_existing {
        self.list_segments();
    }
}

glob __all__ = ["SQLiteRecallFileSegmentRepo"];
