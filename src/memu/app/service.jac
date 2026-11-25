import from typing { Type }
import from collections.abc { Mapping }
import from typing { Any, TypeVar }
import from pydantic { BaseModel }
glob TConfigModel = TypeVar("TConfigModel", bound=BaseModel);

class MemoryService(AgenticMixin) {
    has _embedding_pool: ClientPool,
        database: Database,
        embedding_profiles: dict[str, EmbeddingConfig],
        database_config: any,
        user_config: any;
    def init(
        *,
        database_config: DatabaseConfig | dict[str, Any] | None = None,
        embedding_profiles: EmbeddingProfilesConfig | dict[str, Any] | None = None,
        progressive_retrieve_config: ProgressiveRetrieveConfig | dict[str, Any] | None = None,
        user_config: UserConfig | dict[str, Any] | None = None,
    );
    def _get_database -> Database;
    def _get_embedding_client(profile: str | None = None) -> Any;
    def _normalize_where(where: Mapping[str, Any] | None) -> dict[str, Any];
    def _model_dump_without_embeddings(`obj: BaseModel) -> dict[str, Any];
    static def _validate_config(
        config: Mapping[str, Any] | BaseModel | None, model_type: Type[TConfigModel]
    ) -> TConfigModel;
}
