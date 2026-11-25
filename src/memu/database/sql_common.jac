import builtins;
import operator;
import from collections.abc { Mapping }
import from typing { Any, Optional, Type }
import pendulum;
import from pydantic { BaseModel }
import from sqlalchemy { MetaData }
import from sqlmodel { Index, SQLModel }

def _normalize_table_args(table_args: Any) -> tuple[list[Any], dict[str, Any]];
def _merge_models(
    user_model: Type[BaseModel],
    core_model: Type[SQLModel],
    *,
    name_suffix: str,
    base_attrs: dict[str, Any],
) -> Type[SQLModel];
def build_table_model(
    user_model: Type[BaseModel],
    core_model: Type[SQLModel],
    *,
    tablename: str,
    metadata: MetaData | None = None,
    extra_table_args: Optional[tuple[Any, ...]] = None,
    unique_with_scope: Optional[list[str]] = None,
) -> Type[SQLModel];

class SQLRepoBase(builtins.object) {
    has _scope_fields: list[str],
        _sessions: Any,
        _sqla_models: Any,
        _state: DatabaseState;
    def init(*, state: DatabaseState, sqla_models: Any, sessions: Any, scope_fields: list[str]);
    def _scope_kwargs_from(`obj: Any) -> dict[str, Any];
    def _merge_and_commit(`obj: Any);
    def _now -> pendulum.DateTime;
    def _build_filters(model: Any, where: Mapping[str, Any] | None) -> list[Any];
    static def _matches_where(`obj: Any, where: Mapping[str, Any] | None) -> bool;
}
