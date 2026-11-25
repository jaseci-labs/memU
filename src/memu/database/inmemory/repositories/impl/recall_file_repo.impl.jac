impl InMemoryRecallFileRepository.init(
    *, state: InMemoryState, recall_file_model: Type[RecallFile]
) {
    self._state = state;
    self.recall_file_model = recall_file_model;
    self.recall_files = self._state.recall_files;
}

impl InMemoryRecallFileRepository.list_recall_files(
    where: Mapping[str, Any] | None = None
) -> dict[str, RecallFile] {
    if not where {
        return dict(self.recall_files);
    }
    return {
        rid: recall_file
        for (rid, recall_file) in self.recall_files.items()
        if matches_where(recall_file, where)
    };
}

impl InMemoryRecallFileRepository.list_recall_files_page(
    where: Mapping[str, Any] | None, *, after: Optional[tuple[str, str, str]], limit: int
) -> tuple[list[RecallFile], Optional[tuple[str, str, str]]] {
    matches = [f for f in self.recall_files.values() if not where or matches_where(f, where)];
    matches.sort(key=lambda (f: any) -> any { (f.track, f.name, f.id) });
    if after is not None {
        matches = [f for f in matches if (f.track, f.name, f.id) > after];
    }
    page = matches[:limit];
    has_more = len(matches) > limit;
    next_after = (page[-1].track, page[-1].name, page[-1].id) if has_more else None;
    return (page, next_after);
}

impl InMemoryRecallFileRepository.clear_recall_files(
    where: Mapping[str, Any] | None = None
) -> dict[str, RecallFile] {
    if not where {
        matches = self.recall_files.copy();
        self.recall_files.clear();
        return matches;
    }
    matches = {
        rid: recall_file
        for (rid, recall_file) in self.recall_files.items()
        if matches_where(recall_file, where)
    };
    for rid in matches {
        self.recall_files.pop(rid, None);
    }
    return matches;
}

impl InMemoryRecallFileRepository.get_or_create_recall_file(
    *,
    name: str,
    description: str,
    embedding: list[float],
    user_data: dict[str, Any],
    track: str = "memory",
) -> RecallFile {
    for recall_file in self.recall_files.values() {
        if recall_file.name == name
            and recall_file.track == track
            and all([getattr(recall_file, k) == v for (k, v) in user_data.items()])
        {
            now = pendulum.now("UTC");
            if embedding and (not recall_file.embedding) {
                recall_file.embedding = embedding;
                recall_file.updated_at = now;
            }
            if description and (not recall_file.description) {
                recall_file.description = description;
                recall_file.updated_at = now;
            }
            return recall_file;
        }
    }
    rid = str(uuid.uuid4());
    recall_file = self.recall_file_model(
        id=rid, name=name, description=description, embedding=embedding, track=track, **user_data
    );
    self.recall_files[rid] = recall_file;
    return recall_file;
}

impl InMemoryRecallFileRepository.update_recall_file(
    *,
    recall_file_id: str,
    name: str | None = None,
    description: str | None = None,
    embedding: Optional[list[float]] = None,
    content: str | None = None,
) -> RecallFile {
    recall_file = self.recall_files.get(recall_file_id);
    if recall_file is None {
        raise KeyError(f"RecallFile with id {recall_file_id} not found");
    }
    if name is not None {
        recall_file.name = name;
    }
    if description is not None {
        recall_file.description = description;
    }
    if embedding is not None {
        recall_file.embedding = embedding;
    }
    if content is not None {
        recall_file.content = content;
    }
    recall_file.updated_at = pendulum.now("UTC");
    return recall_file;
}

impl InMemoryRecallFileRepository.load_existing {
    return None;
}
