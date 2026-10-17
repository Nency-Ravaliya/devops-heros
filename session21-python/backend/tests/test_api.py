import os

os.environ["DATABASE_URL"] = "sqlite:///./test.db"

from fastapi.testclient import TestClient
from app.main import app


def test_health():
    with TestClient(app) as client:
        assert client.get("/health").json() == {"status": "UP"}


def test_root():
    with TestClient(app) as client:
        response = client.get("/")
        assert response.status_code == 200
        assert response.json()["service"] == "TaskBoard API"


def test_create_task_validation():
    with TestClient(app) as client:
        response = client.post(
            "/api/tasks",
            json={
                "title": "Deploy application",
                "priority": "HIGH",
                "assignee": "Student",
            },
        )

        assert response.status_code == 201
        assert response.json()["title"] == "Deploy application"