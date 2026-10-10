def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_ready_reports_database_up(client):
    r = client.get("/ready")
    assert r.status_code == 200
    assert r.json()["database"] == "up"


def test_metrics_endpoint_is_prometheus_text(client):
    client.get("/api/entries")
    r = client.get("/metrics")
    assert r.status_code == 200
    assert "http_requests_total" in r.text
    assert "studytrack_entries_created_total" in r.text


def test_list_entries_empty(client):
    r = client.get("/api/entries")
    assert r.status_code == 200
    assert r.json() == []


def test_create_entry(client, sample_entry):
    r = client.post("/api/entries", json=sample_entry)
    assert r.status_code == 201
    body = r.json()
    assert body["id"] == 1
    assert body["subject"] == "Operating Systems"
    assert body["minutes"] == 45
    assert body["status"] == "planned"
    assert "created_at" in body


def test_create_entry_validation(client):
    r = client.post("/api/entries", json={"subject": "", "topic": "x", "minutes": 0})
    assert r.status_code == 422
    r = client.post("/api/entries", json={"subject": "DBMS", "topic": "Joins", "status": "later"})
    assert r.status_code == 422


def test_get_entry_and_404(client, sample_entry):
    created = client.post("/api/entries", json=sample_entry).json()
    r = client.get(f"/api/entries/{created['id']}")
    assert r.status_code == 200
    assert r.json()["topic"] == "Paging and TLB"
    assert client.get("/api/entries/999").status_code == 404


def test_update_entry(client, sample_entry):
    created = client.post("/api/entries", json=sample_entry).json()
    r = client.put(f"/api/entries/{created['id']}", json={"status": "done", "minutes": 60})
    assert r.status_code == 200
    assert r.json()["status"] == "done"
    assert r.json()["minutes"] == 60
    assert r.json()["topic"] == "Paging and TLB"  # untouched field kept
    assert client.put(f"/api/entries/{created['id']}", json={}).status_code == 422
    assert client.put("/api/entries/999", json={"status": "done"}).status_code == 404


def test_delete_entry(client, sample_entry):
    created = client.post("/api/entries", json=sample_entry).json()
    assert client.delete(f"/api/entries/{created['id']}").status_code == 204
    assert client.get(f"/api/entries/{created['id']}").status_code == 404
    assert client.delete(f"/api/entries/{created['id']}").status_code == 404


def test_filter_by_subject_and_status(client, sample_entry):
    client.post("/api/entries", json=sample_entry)
    client.post("/api/entries", json={**sample_entry, "subject": "DBMS", "status": "done"})
    assert len(client.get("/api/entries", params={"subject": "DBMS"}).json()) == 1
    assert len(client.get("/api/entries", params={"status_filter": "done"}).json()) == 1
    assert len(client.get("/api/entries").json()) == 2


def test_summary(client, sample_entry):
    client.post("/api/entries", json={**sample_entry, "minutes": 50, "status": "done"})
    client.post("/api/entries", json={**sample_entry, "subject": "DBMS", "minutes": 90, "status": "done"})
    client.post("/api/entries", json={**sample_entry, "minutes": 20})
    s = client.get("/api/entries/summary").json()
    assert s["total_entries"] == 3
    assert s["total_minutes"] == 160
    assert s["done_minutes"] == 140
    assert s["goal_reached"] is True  # default goal is 120
    assert s["by_status"] == {"done": 2, "planned": 1}
    assert s["by_subject"][0] == {"subject": "DBMS", "minutes": 90, "entries": 1}
