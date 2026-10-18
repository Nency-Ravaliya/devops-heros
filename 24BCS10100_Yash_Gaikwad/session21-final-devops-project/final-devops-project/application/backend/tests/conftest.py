import os

# Tests must never touch a real database: point the app at in-memory SQLite
# before app.database builds its engine.
os.environ["DATABASE_URL"] = "sqlite://"

import itertools

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app


@pytest.fixture()
def client():
    # StaticPool keeps one shared connection so the in-memory DB survives across requests
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    Base.metadata.create_all(engine)

    def override_get_db():
        db = TestingSession()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
    Base.metadata.drop_all(engine)
    engine.dispose()


@pytest.fixture()
def make_item(client):
    """Create an item through the API; every call gets a fresh SKU unless one is given."""
    counter = itertools.count(1)

    def _make(**overrides):
        payload = {
            "sku": f"SKU-{next(counter):03d}",
            "name": "Widget",
            "category": "General",
            "quantity": 50,
            "reorder_level": 10,
            "unit_price": 2.5,
        }
        payload.update(overrides)
        response = client.post("/api/items", json=payload)
        assert response.status_code == 201, response.text
        return response.json()

    return _make
