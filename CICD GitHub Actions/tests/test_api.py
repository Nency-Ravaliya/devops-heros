import pytest

from app.main import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_health(client):
    assert client.get("/health").get_json() == {"status": "ok"}


def test_index_lists_operations(client):
    data = client.get("/").get_json()
    assert data["operations"] == ["add", "divide", "multiply", "subtract"]


def test_add_endpoint(client):
    data = client.get("/api/add?a=2&b=3").get_json()
    assert data["result"] == 5


def test_divide_by_zero_returns_400(client):
    resp = client.get("/api/divide?a=1&b=0")
    assert resp.status_code == 400


def test_unknown_operation_returns_404(client):
    assert client.get("/api/power?a=2&b=3").status_code == 404


def test_bad_input_returns_400(client):
    assert client.get("/api/add?a=x&b=3").status_code == 400
