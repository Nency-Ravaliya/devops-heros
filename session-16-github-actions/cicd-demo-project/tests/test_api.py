import pytest

from app.main import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_add_endpoint(client):
    r = client.get("/calc/add?a=10&b=5")
    assert r.status_code == 200
    assert r.get_json()["result"] == 15


def test_divide_by_zero_endpoint(client):
    r = client.get("/calc/divide?a=1&b=0")
    assert r.status_code == 400
    assert "zero" in r.get_json()["error"]


def test_unknown_operation(client):
    assert client.get("/calc/power?a=2&b=3").status_code == 404


def test_bad_input(client):
    assert client.get("/calc/add?a=ten&b=5").status_code == 400


def test_info_hides_secret_value(client, monkeypatch):
    monkeypatch.setenv("APP_SECRET_KEY", "super-secret")
    body = client.get("/info").get_json()
    assert body["secret_configured"] is True
    assert "super-secret" not in str(body)
