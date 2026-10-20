import pytest

from app.main import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_index(client):
    res = client.get("/")
    assert res.status_code == 200
    assert res.get_json()["app"] == "s17-devsecops-demo"


def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.get_json() == {"status": "ok"}


def test_security_headers(client):
    res = client.get("/health")
    assert res.headers["X-Content-Type-Options"] == "nosniff"
    assert res.headers["X-Frame-Options"] == "DENY"


def test_status(client):
    data = client.get("/api/status").get_json()
    assert data["status"] == "running"
    assert "uptime_seconds" in data


def test_greet_escapes_html(client):
    data = client.get("/api/greet/<script>").get_json()
    assert "<script>" not in data["message"]
    assert "&lt;script&gt;" in data["message"]


@pytest.mark.parametrize(
    "op,a,b,expected",
    [("add", 2, 3, 5), ("subtract", 5, 3, 2), ("multiply", 4, 5, 20), ("divide", 9, 3, 3)],
)
def test_calc(client, op, a, b, expected):
    res = client.post("/api/calc", json={"op": op, "a": a, "b": b})
    assert res.status_code == 200
    assert res.get_json()["result"] == expected


def test_calc_divide_by_zero(client):
    res = client.post("/api/calc", json={"op": "divide", "a": 1, "b": 0})
    assert res.status_code == 400


def test_calc_bad_input(client):
    assert client.post("/api/calc", json={"op": "pow", "a": 1, "b": 1}).status_code == 400
    assert client.post("/api/calc", json={"op": "add", "a": "x", "b": 1}).status_code == 400
    assert client.post("/api/calc", data="not json").status_code == 400


def test_not_found(client):
    assert client.get("/nope").status_code == 404
