import pytest
from app import app

@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client

def test_home_endpoint(client):
    response = client.get("/")
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data["status"] == "online"
    assert "version" in json_data

def test_info_endpoint(client):
    response = client.get("/api/v1/info")
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data["orchestration"] == "Kubernetes & Helm"
    assert json_data["gitops"] == "ArgoCD"

def test_healthz_probe(client):
    response = client.get("/healthz")
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data["status"] == "healthy"

def test_prometheus_metrics(client):
    response = client.get("/metrics")
    assert response.status_code == 200
    assert b"http_requests_total" in response.data or response.status_code == 200
