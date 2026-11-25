import from typing { Any, Protocol, Optional }

class AgenticMemoryBackend(Protocol) {
    async def list_all_recall_files(
        where: Optional[dict[str, Any]] = None, *, cursor: str | None = None, limit: int = 100
    ) -> dict[str, Any] abst;
    async def progressive_retrieve(
        query: str, where: Optional[dict[str, Any]] = None
    ) -> dict[str, Any] abst;
    async def commit_results(
        *,
        recall_files: Optional[list[dict[str, Any]]] = None,
        resource: Optional[list[dict[str, Any]]] = None,
        user: Optional[dict[str, Any]] = None,
    ) -> dict[str, Any] abst;
}
