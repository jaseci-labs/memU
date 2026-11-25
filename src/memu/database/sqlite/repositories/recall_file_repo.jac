import from typing { Type, Optional }
import logging;
import from collections.abc { Mapping }
import from typing { Any }
import from sqlalchemy { tuple_ }
import from sqlmodel { delete, select }
glob logger = logging.getLogger(__name__);

class SQLiteRecallFileRepo(SQLiteRepoBase, RecallFileRepo) {
    has _record_model: Type[RecallFile],
        _recall_file_model: Type[Any];
    def init(
        *,
        state: DatabaseState,
        recall_file_model: Type[Any],
        sqla_models: SQLiteSQLAModels,
        sessions: SQLiteSessionManager,
        scope_fields: list[str],
        record_model: Type[RecallFile] = RecallFile,
    );
    def list_recall_files(where: Mapping[str, Any] | None = None) -> dict[str, RecallFile];
    def list_recall_files_page(
        where: Mapping[str, Any] | None, *, after: Optional[tuple[str, str, str]], limit: int
    ) -> tuple[list[RecallFile], Optional[tuple[str, str, str]]];
    def _row_to_recall_file(row: Any) -> RecallFile;
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
}

glob __all__ = ["SQLiteRecallFileRepo"];
