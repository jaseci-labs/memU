import base64;
import binascii;
import json;
import from collections.abc { Callable, Mapping, Sequence }
import from contextlib { nullcontext }
import from dataclasses { dataclass }
import from typing { Any, Optional }
import from pydantic { BaseModel }
glob DEFAULT_PAGE_LIMIT = 50;

def _encode_cursor(after: Optional[tuple[str, str, str]]) -> str | None {
    return None
        if after is None
        else base64.urlsafe_b64encode(json.dumps(list(after)).encode()).decode();
}

def _decode_cursor(cursor: str | None) -> Optional[tuple[str, str, str]] {
    if not cursor {
        return None;
    }
    try {
        decoded = json.loads(base64.urlsafe_b64decode(cursor.encode()).decode());
    } except (binascii.Error, ValueError) as exc {
        raise ValueError("invalid cursor") from exc;
    }
    if not isinstance(decoded, list)
        or len(decoded) != 3
        or (not all((isinstance(value, str) for value in decoded)))
    {
        raise ValueError("invalid cursor");
    }
    return (decoded[0], decoded[1], decoded[2]);
}

async def _embed_one(embed_client: Any, text: str) -> list[float] {
    vectors: list[list[float]];
    (vectors, _) = await embed_client.embed([text]);
    return vectors[0];
}

glob _UNRESOLVED_TICKET = "embedding ticket redeemed without a planned vector",
     _VECTOR_COUNT_MISMATCH = "embedding provider returned the wrong number of vectors";

class _EmbeddingBatch {
    has _vectors: list[list[float]],
        _texts: list[str],
        _tickets: dict[str, int];

    def init {
        self._tickets = {};
        self._texts = [];
        self._vectors = [];
    }

    def request(text: str) -> int {
        ticket = self._tickets.get(text);
        if ticket is None {
            ticket = len(self._texts);
            self._tickets[text] = ticket;
            self._texts.append(text);
        }
        return ticket;
    }

    async def resolve(embed_client: Any) {
        pending = self._texts[len(self._vectors):];
        if not pending {
            return;
        }
        (vectors, _) = await embed_client.embed(pending);
        if len(vectors) != len(pending) {
            raise ValueError(_VECTOR_COUNT_MISMATCH);
        }
        self._vectors.extend(vectors);
    }

    has resolved: bool {
        getter {
            return len(self._vectors) == len(self._texts);
        }
    }

    def vector(ticket: int | None) -> list[float] {
        if ticket is None {
            raise ValueError(_UNRESOLVED_TICKET);
        }
        return self._vectors[ticket];
    }
}

@dataclass
class _ResourcePlan {
    has url: str,
        caption: str | None,
        caption_ticket: int | None,
        existing: Resource | None,
        stale_ids: list[str];
}

@dataclass
class _SegmentPlan {
    has stale_ids: list[str],
        additions: list[tuple[str, int]];
}

@dataclass
class _RecallFilePlan {
    has name: str,
        track: str,
        description: str,
        content: str,
        existing: RecallFile | None,
        create_ticket: int | None,
        description_ticket: int | None,
        segments: _SegmentPlan;
}

class AgenticMixin {
    has progressive_retrieve_config: any,
        user_model: any;
    def _get_database -> Database abst;
    def _get_embedding_client(profile: str | None = None) -> Any abst;
    def _normalize_where(where: Mapping[str, Any] | None) -> dict[str, Any] abst;
    def _model_dump_without_embeddings(`obj: BaseModel) -> dict[str, Any] abst;

    async def list_all_recall_files(
        where: Optional[dict[str, Any]] = None,
        *,
        cursor: str | None = None,
        limit: int = DEFAULT_PAGE_LIMIT,
    ) -> dict[str, Any] {
        if limit < 1 {
            raise ValueError("limit must be greater than zero");
        }
        store = self._get_database();
        where_filters = self._normalize_where(where);
        with store.snapshot() if isinstance(store, AtomicDatabase) else nullcontext() {
            (recall_files, next_after) = store.recall_file_repo.list_recall_files_page(
                where_filters, after=_decode_cursor(cursor), limit=limit
            );
            recall_files_list = [
                self._model_dump_without_embeddings(recall_file)
                for recall_file in recall_files
            ];
        }
        return {"recall_files": recall_files_list, "next_cursor": _encode_cursor(next_after)};
    }

    async def progressive_retrieve(
        query: str, where: Optional[dict[str, Any]] = None
    ) -> dict[str, Any] {
        if not query or not query.strip() {
            raise ValueError("empty_query");
        }
        store = self._get_database();
        where_filters = self._normalize_where(where);
        config = self.progressive_retrieve_config;
        embed_client = self._get_embedding_client("embedding");
        query_vector = await _embed_one(embed_client, query);
        with store.snapshot() if isinstance(store, AtomicDatabase) else nullcontext() {
            (segment_hits, segment_pool) = self._recall_segments(
                store=store,
                where_filters=where_filters,
                query_vector=query_vector,
                enabled=config.file.enabled,
            );
            (file_hits, file_pool) = self._collect_files(
                store=store,
                where_filters=where_filters,
                segment_hits=segment_hits,
                segment_pool=segment_pool,
            );
            (resource_hits, resource_pool) = self._recall_resources(
                store=store,
                where_filters=where_filters,
                query_vector=query_vector,
                enabled=config.resource.enabled,
            );
            return {
                "segments": self._materialize_hits(segment_hits, segment_pool),
                "files": self._materialize_hits(file_hits, file_pool),
                "resources": self._materialize_hits(resource_hits, resource_pool),
            };
        }
    }

    def _recall_segments(
        *, store: Database, where_filters: dict[str, Any], query_vector: list[float], enabled: bool
    ) -> tuple[list[tuple[str, float]], dict[str, Any]] {
        if not enabled {
            return ([], {});
        }
        segment_where = dict(where_filters);
        tracks = self.progressive_retrieve_config.file.tracks;
        if tracks {
            segment_where["track__in"] = list(tracks);
        }
        hits = store.recall_file_segment_repo.vector_search_segments(
            query_vector, self.progressive_retrieve_config.file.top_k, where=segment_where
        );
        return ([(seg.id, score) for (seg, score) in hits], {seg.id: seg for (seg, _) in hits});
    }

    def _collect_files(
        *,
        store: Database,
        where_filters: dict[str, Any],
        segment_hits: list[tuple[str, float]],
        segment_pool: dict[str, Any],
    ) -> tuple[list[tuple[str, float]], dict[str, Any]] {
        hit_file_ids = {
            seg.recall_file_id
            for (seg_id, _) in segment_hits
            if (seg := segment_pool.get(seg_id)) is not None
        };
        if not hit_file_ids {
            return ([], {});
        }
        file_pool = store.recall_file_repo.list_recall_files({
            **where_filters,
            "id__in": list(hit_file_ids),
        });
        file_scores: dict[str, float] = {};
        for (seg_id, score) in segment_hits {
            seg = segment_pool.get(seg_id);
            if seg is None {
                continue;
            }
            fid = seg.recall_file_id;
            if fid not in file_pool {
                continue;
            }
            score = float(score);
            if fid not in file_scores or score > file_scores[fid] {
                file_scores[fid] = score;
            }
        }
        file_hits = sorted(
            file_scores.items(), key=lambda (kv: any) -> any { kv[1] }, reverse=True
        );
        return (file_hits, file_pool as any);
    }

    def _recall_resources(
        *, store: Database, where_filters: dict[str, Any], query_vector: list[float], enabled: bool
    ) -> tuple[list[tuple[str, float]], dict[str, Any]] {
        if not enabled {
            return ([], {});
        }
        resource_where = {**where_filters, "track": "workspace"};
        resource_pool = store.resource_repo.list_resources(resource_where);
        resource_hits = store.resource_repo.vector_search_resources(
            query_vector, self.progressive_retrieve_config.resource.top_k, where=resource_where
        );
        return (resource_hits, resource_pool as any);
    }

    def _materialize_hits(
        hits: Sequence[tuple[str, float]], pool: dict[str, Any]
    ) -> list[dict[str, Any]] {
        out: list[any] = [];
        for (_id, score) in hits {
            `obj = pool.get(_id);
            if not `obj {
                continue;
            }
            data = self._model_dump_without_embeddings(`obj);
            data["score"] = float(score);
            out.append(data);
        }
        return out;
    }

    async def commit_results(
        *,
        recall_files: Optional[list[dict[str, Any]]] = None,
        resource: Optional[list[dict[str, Any]]] = None,
        user: Optional[dict[str, Any]] = None,
    ) -> dict[str, Any] {
        store = self._get_database();
        user_scope: any = None;
        if user is not None {
            user_scope = self.user_model(**user).model_dump();
        }
        embed_client = self._get_embedding_client("embedding");
        user_data: dict[str, any] = dict(user_scope) if user_scope else {};
        batch = _EmbeddingBatch();
        with store.snapshot() if isinstance(store, AtomicDatabase) else nullcontext() {
            self._plan_resources(resource or [], store=store, user_scope=user_scope, batch=batch);
            self._plan_recall_files(
                recall_files or [], store=store, user_data=user_data, batch=batch
            );
        }
        while True {
            await batch.resolve(embed_client);
            with store.atomic() if isinstance(store, AtomicDatabase) else nullcontext() {
                resource_plans = self._plan_resources(
                    resource or [], store=store, user_scope=user_scope, batch=batch
                );
                file_plans = self._plan_recall_files(
                    recall_files or [], store=store, user_data=user_data, batch=batch
                );
                if not batch.resolved {
                    continue;
                }
                committed_resources = self._write_resources(
                    resource_plans, store=store, user_data=user_data, batch=batch
                );
                committed_files = self._write_recall_files(
                    file_plans, store=store, user_data=user_data, batch=batch
                );
                result: dict[str, Any] = {
                    "resources": [
                        self._model_dump_without_embeddings(r)
                        for r in committed_resources
                    ],
                    "recall_files": [
                        self._model_dump_without_embeddings(f)
                        for f in committed_files
                    ],
                };
            }
            return result;
        }
    }

    def _plan_resources(
        resources: list[dict[str, Any]],
        *,
        store: Database,
        user_scope: Optional[dict[str, Any]],
        batch: _EmbeddingBatch,
    ) -> list[_ResourcePlan] {
        deduped: dict[str, dict[str, Any]] = {};
        for item in resources {
            url = (item.get("path") or "").strip();
            if url {
                deduped[url] = item;
            }
        }
        if not deduped {
            return [];
        }
        existing_by_url: dict[str, list[Resource]] = {url: [] for url in deduped};
        for resource in store.resource_repo.list_resources(where=user_scope or None).values() {
            if resource.url in existing_by_url {
                existing_by_url[resource.url].append(resource);
            }
        }
        plans: list[_ResourcePlan] = [];
        for (url, item) in deduped.items() {
            caption = (item.get("description") or "").strip() or None;
            matches = existing_by_url[url];
            current = matches[0] if matches else None;
            caption_ticket: any = None;
            if caption is not None
                and (current is None or current.caption != caption or (not current.embedding))
            {
                caption_ticket = batch.request(caption);
            }
            plans.append(
                _ResourcePlan(
                    url=url,
                    caption=caption,
                    caption_ticket=caption_ticket,
                    existing=current,
                    stale_ids=[res.id for res in matches[1:]],
                ),
            );
        }
        return plans;
    }

    def _write_resources(
        plans: list[_ResourcePlan],
        *,
        store: Database,
        user_data: dict[str, Any],
        batch: _EmbeddingBatch,
    ) -> list[Resource] {
        committed: list[Resource] = [];
        for plan in plans {
            embedding: Optional[list[float]];
            if plan.caption_ticket is not None {
                embedding = batch.vector(plan.caption_ticket);
            } elif plan.caption and plan.existing is not None {
                embedding = plan.existing.embedding;
            } else {
                embedding = None;
            }
            if plan.existing is None {
                written = store.resource_repo.create_resource(
                    url=plan.url,
                    local_path=plan.url,
                    caption=plan.caption,
                    embedding=embedding,
                    user_data=dict(user_data),
                    track="workspace",
                );
            } else {
                written = store.resource_repo.update_resource(
                    resource_id=plan.existing.id,
                    local_path=plan.url,
                    caption=plan.caption,
                    embedding=embedding,
                    track="workspace",
                );
            }
            for stale_id in plan.stale_ids {
                store.resource_repo.delete_resource(stale_id);
            }
            committed.append(written);
        }
        return committed;
    }

    def _plan_recall_files(
        recall_files: list[dict[str, Any]],
        *,
        store: Database,
        user_data: dict[str, Any],
        batch: _EmbeddingBatch,
    ) -> list[_RecallFilePlan] {
        deduped: dict[tuple[str, str], dict[str, Any]] = {};
        for item in recall_files {
            name = (item.get("name") or "").strip().lower().replace(" ", "-").replace("_", "-");
            if not name {
                raise ValueError("recall-file name must not be empty");
            }
            if any([char in name for char in "/\\\u0000"]) or name in {".", ".."} {
                raise ValueError("recall-file name must not contain path separators or null bytes");
            }
            deduped[item.get("track") or "memory", name] = item;
        }
        existing_by_track: dict[str, dict[str, RecallFile]] = {
            track: {
                f.name: f
                for f in store.recall_file_repo.list_recall_files(
                    where={**user_data, "track": track}
                ).values()
            }
            for track in {track for (track, _) in deduped}
        };
        plans: list[_RecallFilePlan] = [];
        for ((track, name), item) in deduped.items() {
            description = (item.get("description") or "").strip();
            content = (item.get("content") or "").strip();
            existing = existing_by_track[track].get(name);
            create_ticket: any = None;
            description_ticket: any = None;
            if existing is None {
                create_ticket = batch.request(f"{name}: {description}" if description else name);
            } elif description and description != existing.description {
                description_ticket = batch.request(f"{name}: {description}");
            }
            settled_description = description
                if existing is None or description_ticket is not None
                else existing.description;
            plans.append(
                _RecallFilePlan(
                    name=name,
                    track=track,
                    description=description,
                    content=content,
                    existing=existing,
                    create_ticket=create_ticket,
                    description_ticket=description_ticket,
                    segments=self._plan_segments(
                        name=name,
                        description=settled_description,
                        content=content,
                        file_track=track,
                        existing=existing,
                        store=store,
                        batch=batch,
                    ),
                ),
            );
        }
        return plans;
    }

    def _plan_segments(
        *,
        name: str,
        description: str,
        content: str,
        file_track: str,
        existing: RecallFile | None,
        store: Database,
        batch: _EmbeddingBatch,
    ) -> _SegmentPlan {
        new_texts = self._commit_segment_texts_for_file(
            name=name, description=description, content=content, file_track=file_track
        );
        stored = store.recall_file_segment_repo.list_segments_for_file(existing.id)
            if existing
            else [];
        stored_texts = {seg.text for seg in stored};
        new_set = set(new_texts);
        return _SegmentPlan(
            stale_ids=[seg.id for seg in stored if seg.text not in new_set],
            additions=[
                (text, batch.request(text))
                for text in new_texts
                if text not in stored_texts
            ],
        );
    }

    def _write_recall_files(
        plans: list[_RecallFilePlan],
        *,
        store: Database,
        user_data: dict[str, Any],
        batch: _EmbeddingBatch,
    ) -> list[RecallFile] {
        committed: list[RecallFile] = [];
        for plan in plans {
            file = plan.existing;
            if file is None {
                file = store.recall_file_repo.get_or_create_recall_file(
                    name=plan.name,
                    description=plan.description,
                    embedding=batch.vector(plan.create_ticket),
                    user_data=user_data,
                    track=plan.track,
                );
            }
            redescribed = plan.description_ticket is not None;
            file = store.recall_file_repo.update_recall_file(
                recall_file_id=file.id,
                description=plan.description if redescribed else None,
                embedding=batch.vector(plan.description_ticket) if redescribed else None,
                content=plan.content,
            );
            for stale_id in plan.segments.stale_ids {
                store.recall_file_segment_repo.delete_segment(stale_id);
            }
            for (text, ticket) in plan.segments.additions {
                store.recall_file_segment_repo.create_segment(
                    recall_file_id=file.id,
                    track=plan.track,
                    text=text,
                    embedding=batch.vector(ticket),
                    user_data=dict(user_data),
                );
            }
            committed.append(file);
        }
        return committed;
    }

    static def _commit_segment_texts_for_file(
        *, name: str, description: str, content: str, file_track: str
    ) -> list[str] {
        if file_track == "skill" {
            return [f"name: {name}\ndescription: {description}"];
        }
        texts: list[str] = [];
        for line in (content or "").split("\n") {
            stripped = line.strip();
            if not stripped or stripped.startswith("#") {
                continue;
            }
            texts.append(stripped);
        }
        return list(dict.fromkeys(texts));
    }
}
