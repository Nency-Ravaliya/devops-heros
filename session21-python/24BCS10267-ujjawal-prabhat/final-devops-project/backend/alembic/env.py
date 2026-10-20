from logging.config import fileConfig

from alembic import context
from sqlalchemy import text

from app import models  # noqa: F401  (registers the tables on Base.metadata)
from app.db import Base, engine

config = context.config
if config.config_file_name:
    fileConfig(config.config_file_name, disable_existing_loggers=False)

target_metadata = Base.metadata


def run_migrations_offline():
    context.configure(url=str(engine.url), target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    with engine.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            if connection.dialect.name == "postgresql":
                # Several backend pods start at once and each runs the migration in
                # its init container: serialise them with a transaction-level lock.
                connection.execute(text("SELECT pg_advisory_xact_lock(4210267)"))
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
