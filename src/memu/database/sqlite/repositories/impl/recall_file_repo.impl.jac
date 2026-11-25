impl SQLiteRecallFileRepo.init(
    *,
    state: DatabaseState,
    recall_file_model: Type[Any],
    sqla_models: SQLiteSQLAModels,
    sessions: SQLiteSessionManager,
    scope_fields: list[str],
    record_model: Type[RecallFile] = RecallFile,
) {
    super.init(state=state, sqla_models=sqla_models, sessions=sessions, scope_fields=scope_fields);
    self._recall_file_model = recall_file_model;
    self._record_model = record_model;
    self.recall_files = self._state.recall_files;
}

impl SQLiteRecallFileRepo.list_recall_files(
    where: Mapping[str, Any] | None = None
) -> dict[str, RecallFile] {
    with self._sessions.session() as session {
        stmt = select(self._recall_file_model);
        filters = self._build_filters(self._recall_file_model, where);
        if filters {
            stmt = stmt.where(*filters);
        }
        rows = session.exec(stmt).all();
    }
    result: dict[str, RecallFile] = {};
    for row in rows {
        recall_file = self._row_to_recall_file(row);
        result[row.id] = recall_file;
    }
    return result;
}

impl SQLiteRecallFileRepo.list_recall_files_page(
    where: Mapping[str, Any] | None, *, after: Optional[tuple[str, str, str]], limit: int
) -> tuple[list[RecallFile], Optional[tuple[str, str, str]]] {
    model = self._recall_file_model;
    with self._sessions.session() as session {
        stmt = select(model);
        filters = self._build_filters(model, where);
        if filters {
            stmt = stmt.where(*filters);
        }
        if after is not None {
            stmt = stmt.where(operator.gt(tuple_(model.track, model.name, model.id), after));
        }
        stmt = stmt.order_by(model.track, model.name, model.id).limit(limit + 1);
        rows = session.exec(stmt).all();
    }
    has_more = len(rows) > limit;
    rows = rows[:limit];
    files = [self._row_to_recall_file(row) for row in rows];
    next_after = (rows[-1].track, rows[-1].name, rows[-1].id) if has_more else None;
    return (files, next_after);
}

impl SQLiteRecallFileRepo._row_to_recall_file(row: Any) -> RecallFile {
    recall_file = self._record_model(
        id=row.id,
        name=row.name,
        description=row.description,
        embedding=self._normalize_embedding(row.embedding),
        content=row.content,
        track=row.track,
        created_at=row.created_at,
        updated_at=row.updated_at,
        **self._scope_kwargs_from(row),
    );
    self.recall_files[row.id] = recall_file;
    return recall_file;
}

impl SQLiteRecallFileRepo.clear_recall_files(
    where: Mapping[str, Any] | None = None
) -> dict[str, RecallFile] {
    filters = self._build_filters(self._recall_file_model, where);
    with self._sessions.session() as session {
        stmt = select(self._recall_file_model);
        if filters {
            stmt = stmt.where(*filters);
        }
        rows = session.exec(stmt).all();
        deleted: dict[str, RecallFile] = {};
        for row in rows {
            recall_file = self._record_model(
                id=row.id,
                name=row.name,
                description=row.description,
                embedding=self._normalize_embedding(row.embedding),
                content=row.content,
                track=row.track,
                created_at=row.created_at,
                updated_at=row.updated_at,
                **self._scope_kwargs_from(row),
            );
            deleted[row.id] = recall_file;
        }
        if not deleted {
            return {};
        }
        del_stmt = delete(self._recall_file_model);
        if filters {
            del_stmt = del_stmt.where(*filters);
        }
        session.exec(del_stmt);
        session.commit();
        for recall_file_id in deleted {
            self.recall_files.pop(recall_file_id, None);
        }
    }
    return deleted;
}

impl SQLiteRecallFileRepo.get_or_create_recall_file(
    *,
    name: str,
    description: str,
    embedding: list[float],
    user_data: dict[str, Any],
    track: str = "memory",
) -> RecallFile {
    where: dict[str, Any] = {"name": name, "track": track, **user_data};
    with self._sessions.session() as session {
        stmt = select(self._recall_file_model);
        filters = self._build_filters(self._recall_file_model, where);
        if filters {
            stmt = stmt.where(*filters);
        }
        existing = session.exec(stmt).first();
        if existing {
            updated = False;
            if embedding and (not self._normalize_embedding(existing.embedding)) {
                existing.embedding = self._prepare_embedding(embedding);
                updated = True;
            }
            if description and (not existing.description) {
                existing.description = description;
                updated = True;
            }
            if updated {
                existing.updated_at = self._now();
                session.add(existing);
                session.commit();
                session.refresh(existing);
            }
            return self._row_to_recall_file(existing);
        }
        now = self._now();
        row = self._recall_file_model(
            name=name,
            description=description,
            embedding=self._prepare_embedding(embedding),
            content=None,
            track=track,
            created_at=now,
            updated_at=now,
            **user_data,
        );
        session.add(row);
        session.commit();
        session.refresh(row);
    }
    recall_file = self._record_model(
        id=row.id,
        name=row.name,
        description=row.description,
        embedding=embedding,
        content=None,
        track=track,
        created_at=row.created_at,
        updated_at=row.updated_at,
        **user_data,
    );
    self.recall_files[row.id] = recall_file;
    return recall_file;
}

impl SQLiteRecallFileRepo.update_recall_file(
    *,
    recall_file_id: str,
    name: str | None = None,
    description: str | None = None,
    embedding: Optional[list[float]] = None,
    content: str | None = None,
) -> RecallFile {
    with self._sessions.session() as session {
        stmt = select(self._recall_file_model).where(
            operator.eq(self._recall_file_model.id, recall_file_id)
        );
        row = session.exec(stmt).first();
        if row is None {
            raise KeyError(f"RecallFile with id {recall_file_id} not found");
        }
        if name is not None {
            row.name = name;
        }
        if description is not None {
            row.description = description;
        }
        if embedding is not None {
            row.embedding = self._prepare_embedding(embedding);
        }
        if content is not None {
            row.content = content;
        }
        row.updated_at = self._now();
        session.add(row);
        session.commit();
        session.refresh(row);
    }
    recall_file = self._record_model(
        id=row.id,
        name=row.name,
        description=row.description,
        embedding=self._normalize_embedding(row.embedding),
        content=row.content,
        track=row.track,
        created_at=row.created_at,
        updated_at=row.updated_at,
        **self._scope_kwargs_from(row),
    );
    self.recall_files[row.id] = recall_file;
    return recall_file;
}

impl SQLiteRecallFileRepo.load_existing {
    self.list_recall_files();
}
