import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import Base, get_db
from app.main import app


@pytest.fixture
def client():
    url = os.getenv("TEST_DATABASE_URL", "sqlite+pysqlite:///:memory:")
    parsed = make_url(url)
    if parsed.get_backend_name() != "sqlite" and not (parsed.database or "").startswith("test_"):
        raise RuntimeError("TEST_DATABASE_URL must name a disposable database starting with test_")
    kwargs = (
        {"connect_args": {"check_same_thread": False}, "poolclass": StaticPool}
        if parsed.get_backend_name() == "sqlite"
        else {}
    )
    engine = create_engine(url, **kwargs)
    Base.metadata.create_all(engine)
    sessions = sessionmaker(bind=engine, expire_on_commit=False)

    def override_db():
        with sessions() as db:
            yield db

    app.dependency_overrides[get_db] = override_db
    try:
        with TestClient(app) as test_client:
            yield test_client
    finally:
        app.dependency_overrides.clear()
        Base.metadata.drop_all(engine)
        engine.dispose()


@pytest.fixture
def payload():
    return {
        "title": "Cannot access workspace",
        "description": "SSO returns an error after login.",
        "requester": "maya@example.com",
        "priority": "high",
        "status": "open",
        "assignee": "",
    }
