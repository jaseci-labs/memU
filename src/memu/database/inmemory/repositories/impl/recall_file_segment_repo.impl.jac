impl InMemoryFileSegmentRepository.init(
    *, state: InMemoryState, recall_file_segment_model: Type[RecallFileSegment]
) {
    self._state = state;
    self.recall_file_segment_model = recall_file_segment_model;
    self.segments = self._state.segments;
}

impl InMemoryFileSegmentRepository.list_segments(
    where: Mapping[str, Any] | None = None
) -> list[RecallFileSegment] {
    if not where {
        return list(self.segments);
    }
    return [seg for seg in self.segments if matches_where(seg, where)];
}

impl InMemoryFileSegmentRepository.list_segments_for_file(
    recall_file_id: str
) -> list[RecallFileSegment] {
    return [seg for seg in self.segments if seg.recall_file_id == recall_file_id];
}

impl InMemoryFileSegmentRepository.create_segment(
    *,
    recall_file_id: str,
    text: str,
    embedding: list[float] | None,
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

impl InMemoryFileSegmentRepository.delete_segment(segment_id: str) {
    self.segments[:] = [seg for seg in self.segments if seg.id != segment_id];
}

impl InMemoryFileSegmentRepository.delete_segments_for_file(
    recall_file_id: str
) -> list[RecallFileSegment] {
    removed = [seg for seg in self.segments if seg.recall_file_id == recall_file_id];
    self.segments[:] = [seg for seg in self.segments if seg.recall_file_id != recall_file_id];
    return removed;
}

impl InMemoryFileSegmentRepository.clear_segments(
    where: Mapping[str, Any] | None = None
) -> list[RecallFileSegment] {
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

impl InMemoryFileSegmentRepository.load_existing {
    return None;
}
