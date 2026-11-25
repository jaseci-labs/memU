import from collections.abc { Mapping }
import from typing { Any, Protocol, runtime_checkable, Optional }

@runtime_checkable
class RecallFileRepo(Protocol) {
    has recall_files: dict[str, RecallFile];
    def list_recall_files(where: Mapping[str, Any] | None = None) -> dict[str, RecallFile] abst;
    def list_recall_files_page(
        where: Mapping[str, Any] | None, *, after: Optional[tuple[str, str, str]], limit: int
    ) -> tuple[list[RecallFile], Optional[tuple[str, str, str]]] abst;
    def clear_recall_files(where: Mapping[str, Any] | None = None) -> dict[str, RecallFile] abst;
    def get_or_create_recall_file(
        *,
        name: str,
        description: str,
        embedding: list[float],
        user_data: dict[str, Any],
        track: str = "memory",
    ) -> RecallFile abst;
    def update_recall_file(
        *,
        recall_file_id: str,
        name: str | None = None,
        description: str | None = None,
        embedding: Optional[list[float]] = None,
        content: str | None = None,
    ) -> RecallFile abst;
    def load_existing abst;
}
