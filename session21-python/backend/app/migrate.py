"""Serialize Alembic startup across backend replicas with a PostgreSQL lock."""
from alembic import command
from alembic.config import Config
from sqlalchemy import text
from .db import engine


def main():
    with engine.connect() as connection:
        connection.execute(text("SELECT pg_advisory_lock(210021)"))
        try:
            command.upgrade(Config("alembic.ini"), "head")
        finally:
            connection.execute(text("SELECT pg_advisory_unlock(210021)"))


if __name__ == "__main__":
    main()
