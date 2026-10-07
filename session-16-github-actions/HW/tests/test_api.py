import pytest

from app.main import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    return app.test_client()


def test_index_lists_operations(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.get_json()["operations"] == ["add", "divide", "multiply", "subtract"]


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_add_endpoint(client):
    resp = client.get("/api/add?a=2&b=3")
    assert resp.status_code == 200
    assert resp.get_json()["result"] == 5.0


def test_divide_by_zero_returns_400(client):
    resp = client.get("/api/divide?a=1&b=0")
    assert resp.status_code == 400
    assert "zero" in resp.get_json()["error"]


def test_bad_number_returns_400(client):
    resp = client.get("/api/add?a=x&b=1")
    assert resp.status_code == 400


def test_unknown_operation_returns_404(client):
    resp = client.get("/api/power?a=2&b=3")
    assert resp.status_code == 404
