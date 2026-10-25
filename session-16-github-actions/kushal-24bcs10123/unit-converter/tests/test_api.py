from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_units_lists_all_categories():
    body = client.get("/units").json()
    assert set(body) == {"length", "weight", "temperature"}


def test_convert_get():
    r = client.get("/convert/length", params={"value": 2, "from_unit": "mi", "to_unit": "km"})
    assert r.status_code == 200
    assert abs(r.json()["result"] - 3.218688) < 1e-6


def test_convert_post():
    r = client.post("/convert", json={"category": "weight", "value": 16, "from_unit": "oz", "to_unit": "lb"})
    assert r.status_code == 200
    assert abs(r.json()["result"] - 1.0) < 1e-9


def test_bad_unit_is_400():
    r = client.get("/convert/length", params={"value": 1, "from_unit": "m", "to_unit": "cubit"})
    assert r.status_code == 400
    assert "unknown unit" in r.json()["detail"]
