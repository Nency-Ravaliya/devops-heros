import fakeredis
import pytest
import redis

from app.main import create_app


@pytest.fixture
def client():
    app = create_app(redis_client=fakeredis.FakeRedis(decode_responses=True))
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


class BrokenRedis:
    def ping(self):
        raise redis.ConnectionError("connection refused")

    def hvals(self, _):
        raise redis.ConnectionError("connection refused")


def test_index(client):
    data = client.get("/").get_json()
    assert data["app"] == "notes-api"


def test_health(client):
    assert client.get("/health").get_json() == {"status": "ok"}


def test_ready_when_redis_up(client):
    assert client.get("/ready").status_code == 200


def test_ready_when_redis_down():
    app = create_app(redis_client=BrokenRedis())
    resp = app.test_client().get("/ready")
    assert resp.status_code == 503


def test_create_and_list_notes(client):
    assert client.post("/api/notes", json={"text": "buy milk"}).status_code == 201
    client.post("/api/notes", json={"text": "deploy to prod"})
    texts = [n["text"] for n in client.get("/api/notes").get_json()]
    assert texts == ["buy milk", "deploy to prod"]


def test_create_note_requires_text(client):
    assert client.post("/api/notes", json={}).status_code == 400


def test_storage_down_returns_503():
    app = create_app(redis_client=BrokenRedis())
    assert app.test_client().get("/api/notes").status_code == 503


def test_metrics_exposed(client):
    client.get("/health")
    body = client.get("/metrics").get_data(as_text=True)
    assert "notes_http_requests_total" in body


def test_burn(client):
    assert "result" in client.get("/api/burn?n=1000").get_json()
