def make_task(client, **overrides):
    payload = {"title": "Deploy application", "priority": "HIGH", "assignee": "Student"}
    payload.update(overrides)
    response = client.post("/api/tasks", json=payload)
    assert response.status_code == 201, response.text
    return response.json()


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "UP"}


def test_ready_checks_database(client):
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.json() == {"status": "READY"}


def test_root(client):
    response = client.get("/")
    assert response.status_code == 200
    body = response.json()
    assert body["service"] == "TaskBoard API"
    assert body["version"] == "1.0.0"


def test_create_task_with_defaults(client):
    task = make_task(client, priority="LOW")
    assert task["id"] > 0
    assert task["title"] == "Deploy application"
    assert task["status"] == "TODO"
    assert task["description"] == ""
    assert "created_at" in task


def test_create_task_rejects_empty_title(client):
    assert client.post("/api/tasks", json={"title": ""}).status_code == 422


def test_create_task_rejects_unknown_priority(client):
    assert client.post("/api/tasks", json={"title": "x", "priority": "URGENT"}).status_code == 422


def test_list_tasks_newest_first(client):
    first = make_task(client, title="first")
    second = make_task(client, title="second")
    ids = [t["id"] for t in client.get("/api/tasks").json()]
    assert ids == [second["id"], first["id"]]


def test_get_task_and_404(client):
    task = make_task(client)
    assert client.get(f"/api/tasks/{task['id']}").json()["title"] == task["title"]
    assert client.get("/api/tasks/9999").status_code == 404


def test_update_task_partial(client):
    task = make_task(client)
    response = client.put(f"/api/tasks/{task['id']}", json={"status": "IN_PROGRESS"})
    assert response.status_code == 200
    assert response.json()["status"] == "IN_PROGRESS"
    assert response.json()["title"] == task["title"]  # untouched fields are kept


def test_update_missing_task_returns_404(client):
    assert client.put("/api/tasks/9999", json={"status": "DONE"}).status_code == 404


def test_delete_task(client):
    task = make_task(client)
    assert client.delete(f"/api/tasks/{task['id']}").status_code == 204
    assert client.get(f"/api/tasks/{task['id']}").status_code == 404
    assert client.delete(f"/api/tasks/{task['id']}").status_code == 404


def test_stats_counts_by_status(client):
    make_task(client, status="TODO")
    make_task(client, status="IN_PROGRESS")
    make_task(client, status="DONE")
    make_task(client, status="DONE")
    assert client.get("/api/tasks/stats").json() == {"total": 4, "todo": 1, "inProgress": 1, "done": 2}


def test_metrics_endpoint_exposes_prometheus_data(client):
    client.get("/health")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text


def test_cors_allows_only_configured_origins(client):
    allowed = client.get("/health", headers={"Origin": "http://localhost:3000"})
    assert allowed.headers.get("access-control-allow-origin") == "http://localhost:3000"
    blocked = client.get("/health", headers={"Origin": "https://evil.example"})
    assert "access-control-allow-origin" not in blocked.headers
