from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine, text

from app import models  # noqa: F401  (registers the tables on Base.metadata)
from app.config import get_database_url
from app.database import Base

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Emit SQL to stdout without connecting to the database."""
    context.configure(
        url=get_database_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


# Arbitrary constant: every replica asks for the same Postgres advisory lock
MIGRATION_LOCK_ID = 727_274_001


def run_migrations_online() -> None:
    engine = create_engine(get_database_url())
    with engine.connect() as connection:
        if connection.dialect.name == "postgresql":
            # Several replicas start at once in Kubernetes. The lock makes them take turns, so
            # the first one migrates and the others find nothing left to do. A session-level
            # lock is released automatically when this connection closes.
            connection.execute(text("SELECT pg_advisory_lock(:lock_id)"), {"lock_id": MIGRATION_LOCK_ID})
            connection.commit()
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()
    engine.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
