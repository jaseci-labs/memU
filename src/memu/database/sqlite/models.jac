import from typing { Optional, Any }
import uuid;
import from datetime { datetime }
import pendulum;
import from sqlalchemy { JSON, String, Text }
import from sqlmodel { DateTime, Field, SQLModel, func }

class TZDateTime(DateTime) {
    def init(timezone: bool = True, **kw: Any) {
        super.init(timezone=timezone, **kw);
    }
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

glob __all__ = [
    "SQLiteBaseModelMixin",
    "SQLiteRecallFileModel",
    "SQLiteRecallFileSegmentModel",
    "SQLiteResourceModel",
];
