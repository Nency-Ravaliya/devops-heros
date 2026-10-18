from sqlalchemy.orm import Session

from app.database import get_db
from app.main import app


def test_root_returns_service_info(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == "stockpilot-backend"


def test_health_is_ok(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "OK"}


def test_ready_checks_database(client):
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.json() == {"status": "READY"}


def test_ready_returns_503_when_database_is_down(client):
    class BrokenSession(Session):
        def execute(self, *args, **kwargs):
            raise RuntimeError("database unreachable")

    def broken_db():
        yield BrokenSession()

    app.dependency_overrides[get_db] = broken_db
    response = client.get("/ready")
    assert response.status_code == 503
    assert response.json() == {"status": "NOT_READY"}


def test_metrics_exposes_prometheus_format(client):
    client.get("/api/items")  # generate at least one instrumented request
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text
    assert "http_request_duration_seconds" in response.text
    assert 'handler="/api/items"' in response.text


def test_probe_endpoints_are_not_counted_in_metrics(client):
    client.get("/health")
    client.get("/ready")
    assert 'handler="/health"' not in client.get("/metrics").text
