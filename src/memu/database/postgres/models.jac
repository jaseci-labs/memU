import from typing { Type, Optional, Any }
import uuid;
import from datetime { datetime }
import pendulum;
glob Vector: any;

with entry {
    try {
        import from pgvector.sqlalchemy { VECTOR as Vector_ }
        Vector = Vector_;
    } except ImportError as exc {
        raise ImportError("pgvector is required for Postgres vector support") from exc;
    }
}

import from pydantic { BaseModel }
import from sqlalchemy { ForeignKey, String, Text }
import from sqlmodel { Column, DateTime, Field, SQLModel, func }

class TZDateTime(DateTime) {
    def init(timezone: bool = True, **kw: Any) {
        super.init(timezone=timezone, **kw);
    }
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

def build_scoped_models(
    user_model: Type[BaseModel]
) -> tuple[Type[SQLModel], Type[SQLModel], Type[SQLModel]] {
    resource_model = build_table_model(user_model, ResourceModel, tablename="resources");
    recall_file_model = build_table_model(
        user_model, RecallFileModel, tablename="recall_files", unique_with_scope=["name"]
    );
    recall_file_segment_model = build_table_model(
        user_model, RecallFileSegmentModel, tablename="recall_file_segments"
    );
    return (resource_model, recall_file_model, recall_file_segment_model);
}
