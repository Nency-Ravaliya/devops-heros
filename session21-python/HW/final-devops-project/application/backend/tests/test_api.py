import os
import tempfile

DB_FILE = os.path.join(tempfile.mkdtemp(), "test.db")
os.environ["DATABASE_URL"] = f"sqlite:///{DB_FILE}"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy.exc import OperationalError  # noqa: E402

from app.config import Settings  # noqa: E402
from app.db import Base, engine, get_db  # noqa: E402
from app.main import app  # noqa: E402

Base.metadata.create_all(bind=engine)
client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "UP"}
    assert response.headers["X-Content-Type-Options"] == "nosniff"


def test_root():
    body = client.get("/").json()
    assert body["service"] == "TaskBoard API"
    assert body["docs"] == "/docs"


def test_ready_when_db_ok():
    assert client.get("/ready").json() == {"status": "READY"}


def test_ready_returns_503_when_db_down():
    class BrokenSession:
        def execute(self, *_):
            raise OperationalError("select 1", {}, Exception("db down"))

    app.dependency_overrides[get_db] = lambda: BrokenSession()
    try:
        response = client.get("/ready")
    finally:
        app.dependency_overrides.clear()
    assert response.status_code == 503
    assert response.json()["status"] == "NOT_READY"


def test_task_crud_and_stats():
    created = client.post(
        "/api/tasks", json={"title": "Deploy application", "priority": "HIGH", "assignee": "Piyush"}
    )
    assert created.status_code == 201
    task = created.json()
    assert task["status"] == "TODO"

    assert client.get(f"/api/tasks/{task['id']}").json()["title"] == "Deploy application"
    assert any(t["id"] == task["id"] for t in client.get("/api/tasks").json())

    updated = client.put(f"/api/tasks/{task['id']}", json={"status": "DONE"})
    assert updated.status_code == 200
    assert updated.json()["status"] == "DONE"

    stats = client.get("/api/tasks/stats").json()
    assert stats["done"] >= 1
    assert stats["total"] == stats["todo"] + stats["inProgress"] + stats["done"]

    assert client.delete(f"/api/tasks/{task['id']}").status_code == 204
    assert client.get(f"/api/tasks/{task['id']}").status_code == 404


@pytest.mark.parametrize("method", ["get", "put", "delete"])
def test_missing_task_is_404(method):
    kwargs = {"json": {"title": "x"}} if method == "put" else {}
    assert getattr(client, method)("/api/tasks/99999", **kwargs).status_code == 404


def test_validation_rejects_bad_priority():
    response = client.post("/api/tasks", json={"title": "bad", "priority": "URGENT"})
    assert response.status_code == 422


def test_metrics_endpoint():
    client.get("/api/tasks/stats")
    body = client.get("/metrics").text
    assert "http_requests_total" in body
    assert "taskboard_tasks" in body
    assert "taskboard_build_info" in body


def test_settings_build_postgres_url_from_parts():
    s = Settings(database_url=None, db_host="pg", db_port=5432, db_name="tb", db_user="u", db_password="a@b")
    assert s.sqlalchemy_url == "postgresql+psycopg://u:a%40b@pg:5432/tb"
