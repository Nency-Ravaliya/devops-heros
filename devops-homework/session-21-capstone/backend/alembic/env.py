import os

from sqlalchemy import create_engine, pool

from alembic import context
from app.db import DATABASE_URL, Base
from app.models import Ticket  # noqa: F401

target_metadata = Base.metadata
url = os.getenv("DATABASE_URL", DATABASE_URL)

if context.is_offline_mode():
    context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()
else:
    engine = create_engine(url, poolclass=pool.NullPool)
    with engine.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()
