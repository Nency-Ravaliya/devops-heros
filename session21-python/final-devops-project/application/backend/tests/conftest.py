import os

# Point the app at a throwaway SQLite file BEFORE app.config is imported.
os.environ["DATABASE_URL"] = "sqlite:///./test.db"

import pytest
from fastapi.testclient import TestClient

from app.db import Base, engine
from app.main import app


@pytest.fixture()
def client():
    # Fresh schema for every test so tests never depend on each other.
    Base.metadata.drop_all(bind=engine)
    with TestClient(app) as test_client:  # `with` runs the lifespan (create_all)
        yield test_client
    Base.metadata.drop_all(bind=engine)
