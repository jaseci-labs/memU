import from typing { Type }
import logging;
import re;
import from pathlib { Path }
import from typing { Any, Literal }
import from sqlalchemy { create_engine, inspect }
glob msg: any,
     AlembicConfig: any,
     command: any;

with entry {
    try {
        import from alembic { command as command_ }
        command = command_;
        import from alembic.config { Config as AlembicConfig_ }
        AlembicConfig = AlembicConfig_;
    } except ImportError as exc {
        msg = "alembic is required for Postgres migrations";
        raise ImportError(msg) from exc;
    }
}

glob logger = logging.getLogger(__name__),
     DDLMode = Literal["create", "validate"],
     _UNESCAPED_CONFIGPARSER_PERCENT = re.compile("(?<!%)%(?!%)");
def _escape_for_config_parser(value: str) -> str;
def make_alembic_config(*, dsn: str, scope_model: Type[Any]) -> AlembicConfig;
def run_migrations(*, dsn: str, scope_model: Type[Any], ddl_mode: DDLMode = "create");
glob __all__ = ["DDLMode", "make_alembic_config", "run_migrations"];
