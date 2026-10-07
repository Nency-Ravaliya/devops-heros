import pytest

from app import main


@pytest.fixture
def client():
    main.reset()
    main.app.config["TESTING"] = True
    return main.app.test_client()


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_security_headers_present(client):
    resp = client.get("/")
    assert resp.headers["X-Content-Type-Options"] == "nosniff"
    assert resp.headers["X-Frame-Options"] == "DENY"


def test_create_and_get_task(client):
    resp = client.post("/api/tasks", json={"title": "  write README  "})
    assert resp.status_code == 201
    task = resp.get_json()
    assert task == {"id": 1, "title": "write README", "done": False}
    assert client.get("/api/tasks/1").get_json() == task


def test_list_tasks(client):
    client.post("/api/tasks", json={"title": "a"})
    client.post("/api/tasks", json={"title": "b"})
    titles = [t["title"] for t in client.get("/api/tasks").get_json()["tasks"]]
    assert titles == ["a", "b"]


def test_complete_task(client):
    client.post("/api/tasks", json={"title": "scan image"})
    resp = client.post("/api/tasks/1/done")
    assert resp.status_code == 200
    assert resp.get_json()["done"] is True


def test_delete_task(client):
    client.post("/api/tasks", json={"title": "temp"})
    assert client.delete("/api/tasks/1").status_code == 204
    assert client.get("/api/tasks/1").status_code == 404


@pytest.mark.parametrize("body", [None, {}, {"title": ""}, {"title": "   "}, {"title": 5}])
def test_create_rejects_bad_title(client, body):
    resp = client.post("/api/tasks", json=body)
    assert resp.status_code == 400


def test_create_rejects_long_title(client):
    resp = client.post("/api/tasks", json={"title": "x" * 101})
    assert resp.status_code == 400


def test_missing_task_is_404(client):
    assert client.get("/api/tasks/99").status_code == 404
    assert client.post("/api/tasks/99/done").status_code == 404
    assert client.delete("/api/tasks/99").status_code == 404
