import from typing { Type, Optional }
import builtins;
import uuid;
import from datetime { datetime }
import from typing { Any }
import pendulum;
glob msg: any,
     Vector: any;

with entry {
    try {
        import from pgvector.sqlalchemy { VECTOR as Vector_ }
        Vector = Vector_;
    } except ImportError as exc {
        msg = "pgvector is required for Postgres vector support";
        raise ImportError(msg) from exc;
    }
}

import from pydantic { BaseModel }
import from sqlalchemy { ForeignKey, MetaData, String, Text }
import from sqlmodel { Column, DateTime, Field, Index, SQLModel, func }

class TZDateTime(DateTime) {
    def init(timezone: bool = True, **kw: Any);
}

class BaseModelMixin(SQLModel) {
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
    _Mixin = BaseModelMixin;
}

class ResourceModel(_Mixin, Resource) {
    has url: str = Field(sa_column=Column(String, nullable=False)),
        local_path: str = Field(sa_column=Column(String, nullable=False)),
        caption: str | None = Field(default=None, sa_column=Column(Text, nullable=True)),
        embedding: Optional[list[float]] = Field(
            default=None, sa_column=Column(Vector(), nullable=True)
        ),
        track: str | None = Field(default=None, sa_column=Column(String, nullable=True));
}

class RecallFileModel(_Mixin, RecallFile) {
    has name: str = Field(sa_column=Column(String, nullable=False, index=True)),
        description: str = Field(sa_column=Column(Text, nullable=False)),
        embedding: Optional[list[float]] = Field(
            default=None, sa_column=Column(Vector(), nullable=True)
        ),
        content: str | None = Field(default=None, sa_column=Column(Text, nullable=True)),
        track: str = Field(
            default="memory", sa_column=Column(String, nullable=False, server_default="memory")
        );
}

class RecallFileSegmentModel(_Mixin, RecallFileSegment) {
    has recall_file_id: str = Field(
            sa_column=Column(
                ForeignKey("recall_files.id", ondelete="CASCADE"), nullable=False, index=True
            ),
        ),
        track: str = Field(
            default="memory", sa_column=Column(String, nullable=False, server_default="memory")
        ),
        text: str = Field(sa_column=Column(Text, nullable=False)),
        embedding: Optional[list[float]] = Field(
            default=None, sa_column=Column(Vector(), nullable=True)
        );
}

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
def build_scoped_models(
    user_model: Type[BaseModel]
) -> tuple[Type[SQLModel], Type[SQLModel], Type[SQLModel]];
glob __all__ = [
    "BaseModelMixin",
    "RecallFileModel",
    "RecallFileSegmentModel",
    "ResourceModel",
    "build_scoped_models",
    "build_table_model",
];
