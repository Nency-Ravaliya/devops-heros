import os
os.environ["DATABASE_URL"] = "sqlite://"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool
from app.main import app
from app.db import Base, get_db

@pytest.fixture
def client():
    # A fresh database per test; never touch the running PostgreSQL service.
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    Base.metadata.create_all(engine)
    def test_db():
        with Session(engine) as session:
            yield session
    app.dependency_overrides[get_db] = test_db
    try:
        with TestClient(app) as test_client:
            yield test_client
    finally:
        app.dependency_overrides.clear()
        engine.dispose()

def test_health(client):
    assert client.get("/health").json() == {"status": "UP"}

def test_readiness(client):
    assert client.get("/ready").json() == {"status": "READY"}

def test_root(client):
    assert client.get("/").json()["service"] == "TaskBoard API"

def test_create_and_read(client):
    response = client.post("/api/tasks", json={"title": "Deploy Session 21", "assignee": "Chhavi"})
    assert response.status_code == 201
    task = response.json()
    assert client.get(f"/api/tasks/{task['id']}").json()["title"] == "Deploy Session 21"
    assert len(client.get("/api/tasks").json()) == 1

def test_update_and_stats(client):
    task_id = client.post("/api/tasks", json={"title": "Monitor API"}).json()["id"]
    response = client.put(f"/api/tasks/{task_id}", json={"status": "DONE"})
    assert response.status_code == 200
    assert response.json()["status"] == "DONE"
    assert client.get("/api/tasks/stats").json() == {"total": 1, "todo": 0, "inProgress": 0, "done": 1}

def test_delete(client):
    task_id = client.post("/api/tasks", json={"title": "Temporary task"}).json()["id"]
    assert client.delete(f"/api/tasks/{task_id}").status_code == 204
    assert client.get(f"/api/tasks/{task_id}").status_code == 404

def test_invalid_task(client):
    assert client.post("/api/tasks", json={"title": ""}).status_code == 422
    assert client.post("/api/tasks", json={"title": "Test", "priority": "INVALID"}).status_code == 422

def test_missing_task(client):
    assert client.put("/api/tasks/999", json={"status": "DONE"}).status_code == 404
    assert client.delete("/api/tasks/999").status_code == 404

def test_metrics(client):
    client.get("/health")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text
