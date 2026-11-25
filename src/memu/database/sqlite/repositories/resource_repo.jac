import operator;
import from typing { Type, Optional, Any }
import logging;
import from collections.abc { Mapping }
import from sqlmodel { delete, select }
glob logger = logging.getLogger(__name__);

class SQLiteResourceRepo(SQLiteRepoBase, ResourceRepo) {
    has _record_model: Type[Resource],
        _resource_model: Type[Any];

    def init(
        *,
        state: DatabaseState,
        resource_model: Type[Any],
        sqla_models: SQLiteSQLAModels,
        sessions: SQLiteSessionManager,
        scope_fields: list[str],
        record_model: Type[Resource] = Resource,
    ) {
        super.init(
            state=state, sqla_models=sqla_models, sessions=sessions, scope_fields=scope_fields
        );
        self._resource_model = resource_model;
        self._record_model = record_model;
        self.resources = self._state.resources;
    }

    def list_resources(where: Mapping[str, Any] | None = None) -> dict[str, Resource] {
        with self._sessions.session() as session {
            stmt = select(self._resource_model);
            filters = self._build_filters(self._resource_model, where);
            if filters {
                stmt = stmt.where(*filters);
            }
            rows = session.exec(stmt).all();
        }
        result: dict[str, Resource] = {};
        for row in rows {
            res = self._record_model(
                id=row.id,
                url=row.url,
                local_path=row.local_path,
                caption=row.caption,
                embedding=self._normalize_embedding(row.embedding),
                track=row.track,
                created_at=row.created_at,
                updated_at=row.updated_at,
                **self._scope_kwargs_from(row),
            );
            result[row.id] = res;
            self.resources[row.id] = res;
        }
        return result;
    }

    def clear_resources(where: Mapping[str, Any] | None = None) -> dict[str, Resource] {
        filters = self._build_filters(self._resource_model, where);
        with self._sessions.session() as session {
            stmt = select(self._resource_model);
            if filters {
                stmt = stmt.where(*filters);
            }
            rows = session.exec(stmt).all();
            deleted: dict[str, Resource] = {};
            for row in rows {
                res = self._record_model(
                    id=row.id,
                    url=row.url,
                    local_path=row.local_path,
                    caption=row.caption,
                    embedding=self._normalize_embedding(row.embedding),
                    track=row.track,
                    created_at=row.created_at,
                    updated_at=row.updated_at,
                    **self._scope_kwargs_from(row),
                );
                deleted[row.id] = res;
            }
            if not deleted {
                return {};
            }
            del_stmt = delete(self._resource_model);
            if filters {
                del_stmt = del_stmt.where(*filters);
            }
            session.exec(del_stmt);
            session.commit();
            for res_id in deleted {
                self.resources.pop(res_id, None);
            }
        }
        return deleted;
    }

    def delete_resource(resource_id: str) {
        with self._sessions.session() as session {
            session.exec(
                delete(self._resource_model).where(
                    operator.eq(self._resource_model.id, resource_id)
                ),
            );
            session.commit();
        }
        self.resources.pop(resource_id, None);
    }

    def create_resource(
        *,
        url: str,
        local_path: str,
        caption: str | None,
        embedding: Optional[list[float]],
        user_data: dict[str, Any],
        track: str | None = None,
    ) -> Resource {
        now = self._now();
        row = self._resource_model(
            url=url,
            local_path=local_path,
            caption=caption,
            embedding=self._prepare_embedding(embedding),
            track=track,
            created_at=now,
            updated_at=now,
            **user_data,
        );
        with self._sessions.session() as session {
            session.add(row);
            session.commit();
            session.refresh(row);
        }
        res = self._record_model(
            id=row.id,
            url=row.url,
            local_path=row.local_path,
            caption=row.caption,
            embedding=embedding,
            track=row.track,
            created_at=row.created_at,
            updated_at=row.updated_at,
            **user_data,
        );
        self.resources[row.id] = res;
        return res;
    }

    def update_resource(
        *,
        resource_id: str,
        local_path: str,
        caption: str | None,
        embedding: Optional[list[float]],
        track: str | None = None,
    ) -> Resource {
        with self._sessions.session() as session {
            stmt = select(self._resource_model).where(
                operator.eq(self._resource_model.id, resource_id)
            );
            row = session.exec(stmt).first();
            if row is None {
                raise KeyError(f"Resource with id {resource_id} not found");
            }
            row.local_path = local_path;
            row.caption = caption;
            row.embedding = self._prepare_embedding(embedding);
            row.track = track;
            row.updated_at = self._now();
            session.add(row);
            session.commit();
            session.refresh(row);
        }
        res = self._record_model(
            id=row.id,
            url=row.url,
            local_path=row.local_path,
            caption=row.caption,
            embedding=embedding,
            track=row.track,
            created_at=row.created_at,
            updated_at=row.updated_at,
            **self._scope_kwargs_from(row),
        );
        self.resources[row.id] = res;
        return res;
    }

    def vector_search_resources(
        query_vec: list[float], top_k: int, where: Mapping[str, Any] | None = None
    ) -> list[tuple[str, float]] {
        pool = self.list_resources(where);
        corpus = [(rid, res.embedding) for (rid, res) in pool.items() if res.embedding];
        return cosine_topk(query_vec, corpus, k=top_k);
    }

    def load_existing {
        self.list_resources();
    }
}
