import os
import tempfile

import pytest

# Isolated SQLite file per test session - never the real PostgreSQL database.
_tmpdir = tempfile.mkdtemp(prefix="stockpilot-test-")
os.environ["DATABASE_URL"] = f"sqlite:///{_tmpdir}/test.db"
os.environ["APP_ENV"] = "test"

from alembic import command  # noqa: E402
from alembic.config import Config  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import delete  # noqa: E402

from app.db import SessionLocal  # noqa: E402
from app.main import app  # noqa: E402
from app.models import Item  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
def migrated_db():
    """Build the test schema with the same Alembic migrations production uses."""
    command.upgrade(Config("alembic.ini"), "head")


@pytest.fixture()
def client():
    with SessionLocal() as db:
        db.execute(delete(Item))
        db.commit()
    with TestClient(app) as c:
        yield c
