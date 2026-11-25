import from typing { Any, Protocol }

class AgenticMemoryBackend(Protocol) {
    async def list_all_recall_files(
        where: dict[str, Any] | None = None, *, cursor: str | None = None, limit: int = 100
    ) -> dict[str, Any] abst;
    async def progressive_retrieve(
        query: str, where: dict[str, Any] | None = None
    ) -> dict[str, Any] abst;
    async def commit_results(
        *,
        recall_files: list[dict[str, Any]] | None = None,
        resource: list[dict[str, Any]] | None = None,
        user: dict[str, Any] | None = None,
    ) -> dict[str, Any] abst;
}
