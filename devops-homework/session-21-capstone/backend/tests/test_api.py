import pytest
from sqlalchemy.exc import OperationalError

from app.db import get_db
from app.main import app


def test_health_and_ready(client):
    assert client.get("/health").json() == {"status": "healthy"}
    assert client.get("/ready").status_code == 200


def test_create_and_read(client, payload):
    response = client.post("/api/tickets", json=payload)
    assert response.status_code == 201
    ticket = response.json()
    assert ticket["title"] == payload["title"]
    assert ticket["created_at"]
    assert client.get(f"/api/tickets/{ticket['id']}").json() == ticket


def test_update_assignment_and_resolve(client, payload):
    ticket = client.post("/api/tickets", json=payload).json()
    updated = {**payload, "status": "resolved", "assignee": "Nina"}
    response = client.put(f"/api/tickets/{ticket['id']}", json=updated)
    assert response.status_code == 200
    assert response.json()["status"] == "resolved"
    assert client.get("/api/tickets/stats").json()["resolved"] == 1


def test_delete(client, payload):
    ticket = client.post("/api/tickets", json=payload).json()
    assert client.delete(f"/api/tickets/{ticket['id']}").status_code == 204
    assert client.get(f"/api/tickets/{ticket['id']}").status_code == 404
    assert client.get("/api/tickets").json()["total"] == 0


@pytest.mark.parametrize("method", ["get", "put", "delete"])
def test_missing_ticket(client, payload, method):
    kwargs = {"json": payload} if method == "put" else {}
    assert getattr(client, method)("/api/tickets/999999", **kwargs).status_code == 404


@pytest.mark.parametrize(
    "invalid",
    [
        {"title": " "},
        {"title": "a" * 161},
        {"priority": "critical"},
        {"status": "deleted"},
        {"requester": "not-an-email"},
        {"unknown": "value"},
    ],
)
def test_reject_invalid_ticket(client, payload, invalid):
    assert client.post("/api/tickets", json={**payload, **invalid}).status_code == 422


def test_filter_search_and_pagination(client, payload):
    client.post("/api/tickets", json=payload)
    client.post(
        "/api/tickets", json={**payload, "title": "Billing export fails", "status": "resolved"}
    )
    result = client.get("/api/tickets?status=open&priority=high&q=WORKSPACE").json()
    assert result["total"] == 1
    assert result["items"][0]["title"] == payload["title"]
    assert len(client.get("/api/tickets?limit=1&offset=1").json()["items"]) == 1
    assert client.get("/api/tickets?q=%25").json()["total"] == 0
    assert client.get("/api/tickets?limit=101").status_code == 422


def test_stats_exclude_resolved_urgent(client, payload):
    assert client.get("/api/tickets/stats").json()["total"] == 0
    for status in ("open", "in_progress", "resolved"):
        client.post("/api/tickets", json={**payload, "priority": "urgent", "status": status})
    assert client.get("/api/tickets/stats").json() == {
        "total": 3,
        "open": 1,
        "in_progress": 1,
        "resolved": 1,
        "urgent": 2,
    }


def test_readiness_failure_does_not_expose_credentials(client):
    class BrokenSession:
        def execute(self, statement):
            raise OperationalError("secret-db-password", {}, Exception("database unavailable"))

    app.dependency_overrides[get_db] = lambda: BrokenSession()
    response = client.get("/ready")
    assert response.status_code == 503
    assert response.json() == {"status": "not_ready"}
    assert client.get("/health").status_code == 200


def test_metrics_have_bounded_route_labels(client, payload):
    client.get("/api/tickets/987654")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "queuedesk_http_requests_total" in response.text
    assert 'route="/api/tickets/{ticket_id}"' in response.text
    assert 'route="/api/tickets/987654"' not in response.text
