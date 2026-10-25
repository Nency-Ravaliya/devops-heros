from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def setup_function():
    client.delete("/history")


def test_health_and_ready():
    assert client.get("/health").json()["status"] == "ok"
    assert client.get("/ready").json()["ready"] is True


def test_convert_records_history():
    r = client.post("/convert", json={"category": "length", "value": 1, "from_unit": "km", "to_unit": "m"})
    assert r.status_code == 200 and r.json()["result"] == 1000
    assert client.get("/history").json()[0]["result"] == 1000


def test_history_limit_is_validated():
    assert client.get("/history", params={"limit": 0}).status_code == 422
    assert client.get("/history", params={"limit": 99}).status_code == 422


def test_bad_category_is_rejected_by_schema():
    r = client.post("/convert", json={"category": "volume", "value": 1, "from_unit": "l", "to_unit": "ml"})
    assert r.status_code == 422


def test_unknown_unit_is_400():
    r = client.post("/convert", json={"category": "weight", "value": 1, "from_unit": "kg", "to_unit": "ton"})
    assert r.status_code == 400


def test_clear_history():
    client.post("/convert", json={"category": "temperature", "value": 0, "from_unit": "c", "to_unit": "k"})
    assert client.delete("/history").json()["cleared"] is True
    assert client.get("/history").json() == []
