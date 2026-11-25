impl RecallFileSegmentRepo.vector_search_segments(
    query_vec: list[float], top_k: int, where: Mapping[str, Any] | None = None
) -> list[tuple[RecallFileSegment, float]] {
    pool = self.list_segments(where);
    by_id = {seg.id: seg for seg in pool};
    ranked = cosine_topk(query_vec, [(seg.id, seg.embedding) for seg in pool], k=top_k);
    return [(by_id[seg_id], score) for (seg_id, score) in ranked];
}
