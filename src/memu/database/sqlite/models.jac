import from typing { Type, Optional }
import builtins;
import uuid;
import from datetime { datetime }
import from typing { Any }
import pendulum;
import from pydantic { BaseModel }
import from sqlalchemy { JSON, MetaData, String, Text }
import from sqlmodel { DateTime, Field, Index, SQLModel, func }

class TZDateTime(DateTime) {
    def init(timezone: bool = True, **kw: Any);
}

class SQLiteBaseModelMixin(SQLModel) {
    has id: str = Field(
            default_factory=lambda -> any { str(uuid.uuid4()) },
            primary_key=True,
            index=True,
            sa_type=String,
        ),
        created_at: datetime = Field(
            default_factory=lambda -> any { pendulum.now("UTC") },
            sa_type=TZDateTime,
            sa_column_kwargs={"server_default": func.now()},
        ),
        updated_at: datetime = Field(
            default_factory=lambda -> any { pendulum.now("UTC") }, sa_type=TZDateTime
        );
}

glob _Mixin: any;

with entry {
    _Mixin = SQLiteBaseModelMixin;
}

class SQLiteResourceModel(_Mixin, Resource) {
    has url: str = Field(sa_type=String, nullable=False),
        local_path: str = Field(sa_type=String, nullable=False),
        caption: str | None = Field(default=None, sa_type=Text, nullable=True),
        embedding: Optional[list[float]] = Field(default=None, sa_type=JSON, nullable=True),
        track: str | None = Field(default=None, sa_type=String, nullable=True);
}

class SQLiteRecallFileModel(_Mixin, RecallFile) {
    has name: str = Field(sa_type=String, nullable=False, index=True),
        description: str = Field(sa_type=Text, nullable=False),
        embedding: Optional[list[float]] = Field(default=None, sa_type=JSON, nullable=True),
        content: str | None = Field(default=None, sa_type=Text, nullable=True),
        track: str = Field(
            default="memory",
            sa_type=String,
            nullable=False,
            sa_column_kwargs={"server_default": "memory", "default": None},
        );
}

class SQLiteRecallFileSegmentModel(_Mixin, RecallFileSegment) {
    has recall_file_id: str = Field(sa_type=String, nullable=False, index=True),
        track: str = Field(
            default="memory",
            sa_type=String,
            nullable=False,
            sa_column_kwargs={"server_default": "memory", "default": None},
        ),
        text: str = Field(sa_type=Text, nullable=False),
        embedding: Optional[list[float]] = Field(default=None, sa_type=JSON, nullable=True);
}

def _normalize_table_args(table_args: Any) -> tuple[list[Any], dict[str, Any]];
def _merge_models(
    user_model: Type[BaseModel],
    core_model: Type[SQLModel],
    *,
    name_suffix: str,
    base_attrs: dict[str, Any],
) -> Type[SQLModel];
def build_sqlite_table_model(
    user_model: Type[BaseModel],
    core_model: Type[SQLModel],
    *,
    tablename: str,
    metadata: MetaData | None = None,
    extra_table_args: Optional[tuple[Any, ...]] = None,
    unique_with_scope: Optional[list[str]] = None,
) -> Type[SQLModel];
glob __all__ = [
    "SQLiteBaseModelMixin",
    "SQLiteRecallFileModel",
    "SQLiteRecallFileSegmentModel",
    "SQLiteResourceModel",
    "build_sqlite_table_model",
];
