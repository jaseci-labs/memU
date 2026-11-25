import from typing { Type, Optional }
import from collections.abc { Mapping }
import from typing { Any }

class PostgresRecallFileRepo(PostgresRepoBase, RecallFileRepo) {
    has _recall_file_model: Type[RecallFile];
    def init(
        *,
        state: DatabaseState,
        recall_file_model: Type[RecallFile],
        sqla_models: Any,
        sessions: SessionManager,
        scope_fields: list[str],
    );
    def list_recall_files(where: Mapping[str, Any] | None = None) -> dict[str, RecallFile];
    def list_recall_files_page(
        where: Mapping[str, Any] | None, *, after: Optional[tuple[str, str, str]], limit: int
    ) -> tuple[list[RecallFile], Optional[tuple[str, str, str]]];
    def clear_recall_files(where: Mapping[str, Any] | None = None) -> dict[str, RecallFile];
    def get_or_create_recall_file(
        *,
        name: str,
        description: str,
        embedding: list[float],
        user_data: dict[str, Any],
        track: str = "memory",
    ) -> RecallFile;
    def update_recall_file(
        *,
        recall_file_id: str,
        name: str | None = None,
        description: str | None = None,
        embedding: Optional[list[float]] = None,
        content: str | None = None,
    ) -> RecallFile;
    def load_existing;
    def _cache_recall_file(recall_file: RecallFile) -> RecallFile;
}

glob __all__ = ["PostgresRecallFileRepo"];
