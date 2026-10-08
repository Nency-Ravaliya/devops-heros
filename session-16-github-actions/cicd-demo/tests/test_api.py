import pytest

from app.main import app


@pytest.fixture
def client():
    app.testing = True
    return app.test_client()


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_index_reports_version(client, monkeypatch):
    monkeypatch.setenv("APP_VERSION", "abc123")
    assert client.get("/").get_json()["version"] == "abc123"


def test_calc_add(client):
    resp = client.get("/calc/add?a=2&b=3")
    assert resp.status_code == 200
    assert resp.get_json()["result"] == 5


def test_calc_divide_by_zero(client):
    resp = client.get("/calc/divide?a=1&b=0")
    assert resp.status_code == 400


def test_calc_missing_params(client):
    assert client.get("/calc/add?a=1").status_code == 400


def test_calc_unknown_operation(client):
    assert client.get("/calc/power?a=2&b=3").status_code == 404
