impl PostgresResourceRepo.init(
    *,
    state: DatabaseState,
    resource_model: Type[Resource],
    sqla_models: Any,
    sessions: SessionManager,
    scope_fields: list[str],
) {
    super.init(state=state, sqla_models=sqla_models, sessions=sessions, scope_fields=scope_fields);
    self._resource_model = resource_model;
    self.resources = self._state.resources;
}

impl PostgresResourceRepo.list_resources(
    where: Mapping[str, Any] | None = None
) -> dict[str, Resource] {
    import from sqlmodel { select }
    filters = self._build_filters(self._sqla_models.Resource, where);
    with self._sessions.session() as session {
        rows = session.scalars(select(self._sqla_models.Resource).where(*filters)).all();
        result: dict[str, Resource] = {};
        for row in rows {
            row.embedding = self._normalize_embedding(row.embedding);
            res = self._cache_resource(row);
            result[res.id] = res;
        }
    }
    return result;
}

impl PostgresResourceRepo.clear_resources(
    where: Mapping[str, Any] | None = None
) -> dict[str, Resource] {
    import from sqlmodel { delete, select }
    filters = self._build_filters(self._sqla_models.Resource, where);
    with self._sessions.session() as session {
        rows = session.scalars(select(self._sqla_models.Resource).where(*filters)).all();
        deleted: dict[str, Resource] = {};
        for row in rows {
            row.embedding = self._normalize_embedding(row.embedding);
            deleted[row.id] = row;
        }
        if not deleted {
            return {};
        }
        session.exec(delete(self._sqla_models.Resource).where(*filters));
        session.commit();
        for res_id in deleted {
            self.resources.pop(res_id, None);
        }
    }
    return deleted;
}

impl PostgresResourceRepo.delete_resource(resource_id: str) {
    import from sqlmodel { delete }
    with self._sessions.session() as session {
        session.exec(
            delete(self._sqla_models.Resource).where(self._sqla_models.Resource.id == resource_id)
        );
        session.commit();
    }
    self.resources.pop(resource_id, None);
}

impl PostgresResourceRepo.create_resource(
    *,
    url: str,
    local_path: str,
    caption: str | None,
    embedding: list[float] | None,
    user_data: dict[str, Any],
    track: str | None = None,
) -> Resource {
    res = self._resource_model(
        url=url,
        local_path=local_path,
        caption=caption,
        embedding=self._prepare_embedding(embedding),
        track=track,
        **user_data,
        created_at=self._now(),
        updated_at=self._now(),
    );
    with self._sessions.session() as session {
        session.add(res);
        session.commit();
        session.refresh(res);
    }
    return self._cache_resource(res);
}

impl PostgresResourceRepo.update_resource(
    *,
    resource_id: str,
    local_path: str,
    caption: str | None,
    embedding: list[float] | None,
    track: str | None = None,
) -> Resource {
    import from sqlmodel { select }
    with self._sessions.session() as session {
        row = session.scalars(
            select(self._sqla_models.Resource).where(self._sqla_models.Resource.id == resource_id)
        ).first();
        if row is None {
            msg = f"Resource with id {resource_id} not found";
            raise KeyError(msg);
        }
        row.local_path = local_path;
        row.caption = caption;
        row.embedding = self._prepare_embedding(embedding);
        row.track = track;
        row.updated_at = self._now();
        session.add(row);
        session.commit();
        session.refresh(row);
        row.embedding = self._normalize_embedding(row.embedding);
        return self._cache_resource(row);
    }
}

impl PostgresResourceRepo.vector_search_resources(
    query_vec: list[float], top_k: int, where: Mapping[str, Any] | None = None
) -> list[tuple[str, float]] {
    pool = self.list_resources(where);
    corpus = [(rid, res.embedding) for (rid, res) in pool.items() if res.embedding];
    return cosine_topk(query_vec, corpus, k=top_k);
}

impl PostgresResourceRepo.load_existing {
    import from sqlmodel { select }
    with self._sessions.session() as session {
        rows = session.scalars(select(self._sqla_models.Resource)).all();
        for row in rows {
            row.embedding = self._normalize_embedding(row.embedding);
            self._cache_resource(row);
        }
    }
}

impl PostgresResourceRepo._cache_resource(res: Resource) -> Resource {
    self.resources[res.id] = res;
    return res;
}
