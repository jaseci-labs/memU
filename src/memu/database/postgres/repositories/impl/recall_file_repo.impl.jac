impl PostgresRecallFileRepo.init(
    *,
    state: DatabaseState,
    recall_file_model: Type[RecallFile],
    sqla_models: Any,
    sessions: SessionManager,
    scope_fields: list[str],
) {
    super.init(state=state, sqla_models=sqla_models, sessions=sessions, scope_fields=scope_fields);
    self._recall_file_model = recall_file_model;
    self.recall_files = self._state.recall_files;
}

impl PostgresRecallFileRepo.list_recall_files(
    where: Mapping[str, Any] | None = None
) -> dict[str, RecallFile] {
    import from sqlmodel { select }
    filters = self._build_filters(self._sqla_models.RecallFile, where);
    with self._sessions.session() as session {
        rows = session.scalars(select(self._sqla_models.RecallFile).where(*filters)).all();
        result: dict[str, RecallFile] = {};
        for row in rows {
            row.embedding = self._normalize_embedding(row.embedding);
            recall_file = self._cache_recall_file(row);
            result[recall_file.id] = recall_file;
        }
    }
    return result;
}

impl PostgresRecallFileRepo.list_recall_files_page(
    where: Mapping[str, Any] | None, *, after: Optional[tuple[str, str, str]], limit: int
) -> tuple[list[RecallFile], Optional[tuple[str, str, str]]] {
    import from sqlalchemy { tuple_ }
    import from sqlmodel { select }
    model = self._sqla_models.RecallFile;
    filters = self._build_filters(model, where);
    with self._sessions.session() as session {
        stmt = select(model).where(*filters);
        if after is not None {
            stmt = stmt.where(operator.gt(tuple_(model.track, model.name, model.id), after));
        }
        stmt = stmt.order_by(model.track, model.name, model.id).limit(limit + 1);
        rows = session.scalars(stmt).all();
        has_more = len(rows) > limit;
        rows = rows[:limit];
        files: list[RecallFile] = [];
        for row in rows {
            row.embedding = self._normalize_embedding(row.embedding);
            files.append(self._cache_recall_file(row));
        }
    }
    next_after = (files[-1].track, files[-1].name, files[-1].id) if has_more else None;
    return (files, next_after);
}

impl PostgresRecallFileRepo.clear_recall_files(
    where: Mapping[str, Any] | None = None
) -> dict[str, RecallFile] {
    import from sqlmodel { delete, select }
    filters = self._build_filters(self._sqla_models.RecallFile, where);
    with self._sessions.session() as session {
        rows = session.scalars(select(self._sqla_models.RecallFile).where(*filters)).all();
        deleted: dict[str, RecallFile] = {};
        for row in rows {
            row.embedding = self._normalize_embedding(row.embedding);
            deleted[row.id] = row;
        }
        if not deleted {
            return {};
        }
        session.exec(delete(self._sqla_models.RecallFile).where(*filters));
        session.commit();
        for recall_file_id in deleted {
            self.recall_files.pop(recall_file_id, None);
        }
    }
    return deleted;
}

impl PostgresRecallFileRepo.get_or_create_recall_file(
    *,
    name: str,
    description: str,
    embedding: list[float],
    user_data: dict[str, Any],
    track: str = "memory",
) -> RecallFile {
    import from sqlmodel { select }
    now = self._now();
    with self._sessions.session() as session {
        filters = [
            operator.eq(self._sqla_models.RecallFile.name, name),
            operator.eq(self._sqla_models.RecallFile.track, track),
        ];
        for (key, value) in user_data.items() {
            filters.append(operator.eq(getattr(self._sqla_models.RecallFile, key), value));
        }
        existing = session.scalar(select(self._sqla_models.RecallFile).where(*filters));
        if existing {
            updated = False;
            if embedding and (not self._normalize_embedding(getattr(existing, "embedding", None))) {
                existing.embedding = self._prepare_embedding(embedding);
                updated = True;
            }
            if description and (not getattr(existing, "description", "")) {
                existing.description = description;
                updated = True;
            }
            if updated {
                existing.updated_at = now;
                session.add(existing);
                session.commit();
                session.refresh(existing);
            }
            return self._cache_recall_file(existing);
        }
        recall_file = self._recall_file_model(
            name=name,
            description=description,
            embedding=self._prepare_embedding(embedding),
            track=track,
            created_at=now,
            updated_at=now,
            **user_data,
        );
        session.add(recall_file);
        session.commit();
        session.refresh(recall_file);
    }
    return self._cache_recall_file(recall_file);
}

impl PostgresRecallFileRepo.update_recall_file(
    *,
    recall_file_id: str,
    name: str | None = None,
    description: str | None = None,
    embedding: Optional[list[float]] = None,
    content: str | None = None,
) -> RecallFile {
    import from sqlmodel { select }
    now = self._now();
    with self._sessions.session() as session {
        recall_file = session.scalar(
            select(self._sqla_models.RecallFile).where(
                operator.eq(self._sqla_models.RecallFile.id, recall_file_id)
            ),
        );
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
            recall_file.embedding = self._prepare_embedding(embedding);
        }
        if content is not None {
            recall_file.content = content;
        }
        recall_file.updated_at = now;
        session.add(recall_file);
        session.commit();
        session.refresh(recall_file);
        recall_file.embedding = self._normalize_embedding(recall_file.embedding);
    }
    return self._cache_recall_file(recall_file);
}

impl PostgresRecallFileRepo.load_existing {
    import from sqlmodel { select }
    with self._sessions.session() as session {
        rows = session.scalars(select(self._sqla_models.RecallFile)).all();
        for row in rows {
            row.embedding = self._normalize_embedding(row.embedding);
            self._cache_recall_file(row);
        }
    }
}

impl PostgresRecallFileRepo._cache_recall_file(recall_file: RecallFile) -> RecallFile {
    self.recall_files[recall_file.id] = recall_file;
    return recall_file;
}
