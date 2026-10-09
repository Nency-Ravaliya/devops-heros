import os
from pathlib import Path

import pytest

test_db = Path("/tmp/labtrack-test.db")
test_db.unlink(missing_ok=True)
os.environ["DATABASE_URL"] = f"sqlite:///{test_db}"

from fastapi.testclient import TestClient

from app.db import Base, engine
from app.main import app

client = TestClient(app)


@pytest.fixture(autouse=True)
def reset_database():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


def lab_payload(**changes):
    payload = {
        "title": "Deploy a local Kubernetes app",
        "objective": "Package the application with Helm and verify its health checks.",
        "tool": "Kubernetes",
        "difficulty": "INTERMEDIATE",
        "status": "PLANNED",
        "owner": "Anshal Kumar",
    }
    payload.update(changes)
    return payload


def test_health_and_readiness():
    assert client.get("/health").json() == {"status": "UP"}
    assert client.get("/ready").json() == {"status": "READY"}


def test_root_describes_service():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == "LabTrack API"
    assert response.json()["docs"] == "/docs"


def test_create_and_list_labs():
    created = client.post("/api/labs", json=lab_payload())
    assert created.status_code == 201
    assert created.json()["title"] == "Deploy a local Kubernetes app"

    labs = client.get("/api/labs")
    assert labs.status_code == 200
    assert len(labs.json()) == 1


def test_get_one_lab():
    lab_id = client.post("/api/labs", json=lab_payload()).json()["id"]
    response = client.get(f"/api/labs/{lab_id}")
    assert response.status_code == 200
    assert response.json()["tool"] == "Kubernetes"


def test_update_lab_status():
    lab_id = client.post("/api/labs", json=lab_payload()).json()["id"]
    response = client.put(f"/api/labs/{lab_id}", json={"status": "RUNNING"})
    assert response.status_code == 200
    assert response.json()["status"] == "RUNNING"


def test_delete_lab():
    lab_id = client.post("/api/labs", json=lab_payload()).json()["id"]
    assert client.delete(f"/api/labs/{lab_id}").status_code == 204
    assert client.get(f"/api/labs/{lab_id}").status_code == 404


def test_invalid_difficulty_is_rejected():
    response = client.post("/api/labs", json=lab_payload(difficulty="IMPOSSIBLE"))
    assert response.status_code == 422


def test_stats_group_labs_by_status():
    client.post("/api/labs", json=lab_payload(status="PLANNED"))
    client.post("/api/labs", json=lab_payload(title="Observe metrics", status="COMPLETED"))

    response = client.get("/api/labs/stats")
    assert response.status_code == 200
    assert response.json() == {"total": 2, "planned": 1, "running": 0, "completed": 1}
