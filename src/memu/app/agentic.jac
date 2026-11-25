import base64;
import binascii;
import json;
import from collections.abc { Callable, Mapping, Sequence }
import from contextlib { nullcontext }
import from dataclasses { dataclass }
import from typing { Any, Optional }
import from pydantic { BaseModel }
glob DEFAULT_PAGE_LIMIT = 50;
def _encode_cursor(after: Optional[tuple[str, str, str]]) -> str | None;
def _decode_cursor(cursor: str | None) -> Optional[tuple[str, str, str]];
async def _embed_one(embed_client: Any, text: str) -> list[float];
glob _UNRESOLVED_TICKET = "embedding ticket redeemed without a planned vector",
     _VECTOR_COUNT_MISMATCH = "embedding provider returned the wrong number of vectors";

class _EmbeddingBatch {
    has _vectors: list[list[float]],
        _texts: list[str],
        _tickets: dict[str, int];
    def init;
    def request(text: str) -> int;
    async def resolve(embed_client: Any);

    has resolved: bool {
        getter {
            return len(self._vectors) == len(self._texts);
        }
    }

    def vector(ticket: int | None) -> list[float];
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
    ) -> dict[str, Any];
    async def progressive_retrieve(
        query: str, where: Optional[dict[str, Any]] = None
    ) -> dict[str, Any];
    def _recall_segments(
        *, store: Database, where_filters: dict[str, Any], query_vector: list[float], enabled: bool
    ) -> tuple[list[tuple[str, float]], dict[str, Any]];
    def _collect_files(
        *,
        store: Database,
        where_filters: dict[str, Any],
        segment_hits: list[tuple[str, float]],
        segment_pool: dict[str, Any],
    ) -> tuple[list[tuple[str, float]], dict[str, Any]];
    def _recall_resources(
        *, store: Database, where_filters: dict[str, Any], query_vector: list[float], enabled: bool
    ) -> tuple[list[tuple[str, float]], dict[str, Any]];
    def _materialize_hits(
        hits: Sequence[tuple[str, float]], pool: dict[str, Any]
    ) -> list[dict[str, Any]];
    async def commit_results(
        *,
        recall_files: Optional[list[dict[str, Any]]] = None,
        resource: Optional[list[dict[str, Any]]] = None,
        user: Optional[dict[str, Any]] = None,
    ) -> dict[str, Any];
    def _plan_resources(
        resources: list[dict[str, Any]],
        *,
        store: Database,
        user_scope: Optional[dict[str, Any]],
        batch: _EmbeddingBatch,
    ) -> list[_ResourcePlan];
    def _write_resources(
        plans: list[_ResourcePlan],
        *,
        store: Database,
        user_data: dict[str, Any],
        batch: _EmbeddingBatch,
    ) -> list[Resource];
    def _plan_recall_files(
        recall_files: list[dict[str, Any]],
        *,
        store: Database,
        user_data: dict[str, Any],
        batch: _EmbeddingBatch,
    ) -> list[_RecallFilePlan];
    def _plan_segments(
        *,
        name: str,
        description: str,
        content: str,
        file_track: str,
        existing: RecallFile | None,
        store: Database,
        batch: _EmbeddingBatch,
    ) -> _SegmentPlan;
    def _write_recall_files(
        plans: list[_RecallFilePlan],
        *,
        store: Database,
        user_data: dict[str, Any],
        batch: _EmbeddingBatch,
    ) -> list[RecallFile];
    static def _commit_segment_texts_for_file(
        *, name: str, description: str, content: str, file_track: str
    ) -> list[str];
}
