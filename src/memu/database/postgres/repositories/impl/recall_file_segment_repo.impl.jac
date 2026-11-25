impl PostgresRecallFileSegmentRepo.init(
    *,
    state: DatabaseState,
    recall_file_segment_model: Type[RecallFileSegment],
    sqla_models: Any,
    sessions: SessionManager,
    scope_fields: list[str],
    use_vector: bool = True,
) {
    super.init(
        state=state,
        sqla_models=sqla_models,
        sessions=sessions,
        scope_fields=scope_fields,
        use_vector=use_vector,
    );
    self._recall_file_segment_model = recall_file_segment_model;
    self.segments = self._state.segments;
}

impl PostgresRecallFileSegmentRepo._row_to_record(row: Any) -> RecallFileSegment {
    return RecallFileSegment(
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

impl PostgresRecallFileSegmentRepo._cache_segment(row: Any) -> RecallFileSegment {
    seg = self._row_to_record(row);
    if not any((s.id == seg.id for s in self.segments)) {
        self.segments.append(seg);
    }
    return seg;
}

impl PostgresRecallFileSegmentRepo.list_segments(
    where: Mapping[str, Any] | None = None
) -> list[RecallFileSegment] {
    import from sqlmodel { select }
    filters = self._build_filters(self._sqla_models.RecallFileSegment, where);
    with self._sessions.session() as session {
        rows = session.scalars(select(self._sqla_models.RecallFileSegment).where(*filters)).all();
        return [self._cache_segment(row) for row in rows];
    }
}

impl PostgresRecallFileSegmentRepo.list_segments_for_file(
    recall_file_id: str
) -> list[RecallFileSegment] {
    return self.list_segments({"recall_file_id": recall_file_id});
}

impl PostgresRecallFileSegmentRepo.vector_search_segments(
    query_vec: list[float], top_k: int, where: Mapping[str, Any] | None = None
) -> list[tuple[RecallFileSegment, float]] {
    if top_k <= 0 {
        return [];
    }
    if not self._use_vector {
        return super.vector_search_segments(query_vec, top_k, where);
    }
    import from sqlmodel { select }
    model = self._sqla_models.RecallFileSegment;
    distance = model.embedding.cosine_distance(query_vec);
    filters = [*self._build_filters(model, where), model.embedding.is_not(None)];
    with self._sessions.session() as session {
        rows = session.exec(
            select(model, distance.label("distance")).where(*filters).order_by(distance).limit(
                top_k
            ),
        ).all();
        return [(self._cache_segment(row), 1.0 - float(dist)) for (row, dist) in rows];
    }
}

impl PostgresRecallFileSegmentRepo.create_segment(
    *,
    recall_file_id: str,
    text: str,
    embedding: Optional[list[float]],
    user_data: dict[str, Any],
    track: str = "memory",
) -> RecallFileSegment {
    now = self._now();
    row = self._recall_file_segment_model(
        recall_file_id=recall_file_id,
        track=track,
        text=text,
        embedding=self._prepare_embedding(embedding),
        created_at=now,
        updated_at=now,
        **user_data,
    );
    with self._sessions.session() as session {
        session.add(row);
        session.commit();
        session.refresh(row);
        return self._cache_segment(row);
    }
}

impl PostgresRecallFileSegmentRepo.delete_segment(segment_id: str) {
    import from sqlmodel { delete }
    with self._sessions.session() as session {
        session.exec(
            delete(self._sqla_models.RecallFileSegment).where(
                operator.eq(self._sqla_models.RecallFileSegment.id, segment_id)
            ),
        );
        session.commit();
    }
    self.segments[:] = [seg for seg in self.segments if seg.id != segment_id];
}

impl PostgresRecallFileSegmentRepo.delete_segments_for_file(
    recall_file_id: str
) -> list[RecallFileSegment] {
    import from sqlmodel { delete, select }
    with self._sessions.session() as session {
        rows = session.scalars(
            select(self._sqla_models.RecallFileSegment).where(
                operator.eq(self._sqla_models.RecallFileSegment.recall_file_id, recall_file_id)
            ),
        ).all();
        removed = [self._row_to_record(row) for row in rows];
        if removed {
            session.exec(
                delete(self._sqla_models.RecallFileSegment).where(
                    operator.eq(self._sqla_models.RecallFileSegment.recall_file_id, recall_file_id)
                ),
            );
            session.commit();
        }
    }
    self.segments[:] = [seg for seg in self.segments if seg.recall_file_id != recall_file_id];
    return removed;
}

impl PostgresRecallFileSegmentRepo.clear_segments(
    where: Mapping[str, Any] | None = None
) -> list[RecallFileSegment] {
    import from sqlmodel { delete, select }
    filters = self._build_filters(self._sqla_models.RecallFileSegment, where);
    with self._sessions.session() as session {
        rows = session.scalars(select(self._sqla_models.RecallFileSegment).where(*filters)).all();
        removed = [self._row_to_record(row) for row in rows];
        if removed {
            session.exec(delete(self._sqla_models.RecallFileSegment).where(*filters));
            session.commit();
        }
    }
    removed_ids = {seg.id for seg in removed};
    self.segments[:] = [seg for seg in self.segments if seg.id not in removed_ids];
    return removed;
}

impl PostgresRecallFileSegmentRepo.load_existing {
    import from sqlmodel { select }
    with self._sessions.session() as session {
        rows = session.scalars(select(self._sqla_models.RecallFileSegment)).all();
        for row in rows {
            self._cache_segment(row);
        }
    }
}
