import pytest
from app.app import app


# ── Setup ──────────────────────────────────────────────

@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


# ── Test 1: Home page loads ────────────────────────────

def test_home(client):
    response = client.get("/")
    assert response.status_code == 200


# ── Test 2: Health check returns healthy ───────────────

def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200

    data = response.get_json()
    assert data["status"] == "healthy"


# ── Test 3: Greet returns 200 and includes the name ───

def test_greet(client):
    response = client.get("/api/greet/Nensi")
    assert response.status_code == 200

    data = response.get_json()
    # The response contains a random greeting — just check the name is in it
    assert "Nensi" in data["message"]


# ── Test 4: Add numbers returns correct result ─────────

def test_add_numbers(client):
    response = client.post(
        "/api/add",
        json={"number1": 10, "number2": 20}
    )
    assert response.status_code == 200

    data = response.get_json()
    assert data["result"] == 30


# ── Test 5: Add numbers — missing fields returns 400 ──

def test_add_numbers_missing_fields(client):
    response = client.post(
        "/api/add",
        json={"number1": 5}   # number2 is missing
    )
    assert response.status_code == 400


# ── Test 6: Calculator — multiply ─────────────────────

def test_calculator_multiply(client):
    response = client.post(
        "/api/calculate",
        json={"a": 4, "b": 5, "operation": "multiply"}
    )
    assert response.status_code == 200

    data = response.get_json()
    assert data["result"] == 20


# ── Test 7: Calculator — divide by zero ───────────────

def test_calculator_divide_by_zero(client):
    response = client.post(
        "/api/calculate",
        json={"a": 10, "b": 0, "operation": "divide"}
    )
    assert response.status_code == 400


# ── Test 8: Status API ─────────────────────────────────

def test_status(client):
    response = client.get("/api/status")
    assert response.status_code == 200

    data = response.get_json()
    assert data["status"] == "running"
    assert "python_version" in data
    assert "uptime" in data

# ── Test 9: Calculator — unknown operation returns 400 ─

def test_calculator_unknown_operation(client):
    response = client.post("/api/calculate", json={"a": 1, "b": 2, "operation": "sqrt"})
    assert response.status_code == 400


# ── Test 10: Pipeline simulator — no failures ─────────

def test_pipeline_run_all_pass(client):
    response = client.post("/api/pipeline/run", json={"branch": "main", "fail_chance": 0})
    assert response.status_code == 200

    data = response.get_json()
    assert data["branch"] == "main"
    assert data["overall_status"] == "passed"
    assert all(stage["status"] == "passed" for stage in data["stages"])


# ── Test 11: Pipeline simulator — first stage fails ───

def test_pipeline_run_failure_skips_rest(client):
    data = client.post("/api/pipeline/run", json={"fail_chance": 1}).get_json()
    assert data["stages"][0]["status"] == "failed"
    assert all(stage["status"] == "skipped" for stage in data["stages"][1:])


# ── Test 12: Unknown route returns JSON 404 ───────────

def test_not_found(client):
    response = client.get("/does-not-exist")
    assert response.status_code == 404
    assert response.get_json()["code"] == 404
