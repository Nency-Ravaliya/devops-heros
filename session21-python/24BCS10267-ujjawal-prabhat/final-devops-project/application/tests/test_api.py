def _create(client, sku="BOLT-M8", qty=50, reorder=10, price=250, name="M8 bolt"):
    r = client.post(
        "/api/items",
        json={"sku": sku, "name": name, "quantity": qty, "reorder_level": reorder, "unit_price_paise": price},
    )
    assert r.status_code == 201, r.text
    return r.json()


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "UP"}


def test_ready_checks_database(client):
    r = client.get("/ready")
    assert r.status_code == 200
    assert r.json()["status"] == "READY"


def test_index_page_served(client):
    r = client.get("/")
    assert r.status_code == 200
    assert "StockPilot" in r.text


def test_info_reports_env(client):
    assert client.get("/api/info").json()["env"] == "test"


def test_create_and_get_item(client):
    item = _create(client)
    assert item["sku"] == "BOLT-M8"
    assert item["low_stock"] is False
    r = client.get(f"/api/items/{item['id']}")
    assert r.status_code == 200
    assert r.json()["name"] == "M8 bolt"


def test_duplicate_sku_conflict(client):
    _create(client)
    r = client.post("/api/items", json={"sku": "BOLT-M8", "name": "dup"})
    assert r.status_code == 409


def test_invalid_sku_rejected(client):
    r = client.post("/api/items", json={"sku": "bad sku!", "name": "x"})
    assert r.status_code == 422


def test_default_reorder_level_from_config(client):
    r = client.post("/api/items", json={"sku": "NUT-M8", "name": "M8 nut", "quantity": 3})
    assert r.status_code == 201
    assert r.json()["reorder_level"] == 10
    assert r.json()["low_stock"] is True


def test_list_and_filter_by_location(client):
    _create(client, sku="A-1")
    client.post("/api/items", json={"sku": "B-1", "name": "b", "location": "WH2", "quantity": 1})
    assert len(client.get("/api/items").json()) == 2
    wh2 = client.get("/api/items", params={"location": "WH2"}).json()
    assert [i["sku"] for i in wh2] == ["B-1"]


def test_update_item(client):
    item = _create(client)
    r = client.put(f"/api/items/{item['id']}", json={"quantity": 5, "location": "WH3"})
    assert r.status_code == 200
    body = r.json()
    assert body["quantity"] == 5 and body["location"] == "WH3" and body["low_stock"] is True


def test_adjust_stock_in_and_out(client):
    item = _create(client, qty=20)
    r = client.post(f"/api/items/{item['id']}/adjust", json={"delta": -15, "reason": "order-42"})
    assert r.status_code == 200 and r.json()["quantity"] == 5
    r = client.post(f"/api/items/{item['id']}/adjust", json={"delta": 100})
    assert r.json()["quantity"] == 105


def test_adjust_stock_cannot_go_negative(client):
    item = _create(client, qty=2)
    r = client.post(f"/api/items/{item['id']}/adjust", json={"delta": -3})
    assert r.status_code == 422


def test_low_stock_and_summary(client):
    _create(client, sku="LOW-1", qty=2, reorder=5, price=100)
    _create(client, sku="OK-1", qty=50, reorder=5, price=10)
    low = client.get("/api/items/low-stock").json()
    assert [i["sku"] for i in low] == ["LOW-1"]
    s = client.get("/api/summary").json()
    assert s == {"total_items": 2, "total_units": 52, "low_stock_items": 1, "inventory_value_paise": 700}


def test_delete_item_and_404(client):
    item = _create(client)
    assert client.delete(f"/api/items/{item['id']}").status_code == 204
    assert client.get(f"/api/items/{item['id']}").status_code == 404
    assert client.delete(f"/api/items/{item['id']}").status_code == 404
    assert client.put("/api/items/999", json={"name": "x"}).status_code == 404


def test_metrics_exposed(client):
    _create(client, sku="LOW-9", qty=0)
    client.get("/health")
    r = client.get("/metrics")
    assert r.status_code == 200
    body = r.text
    assert 'stockpilot_http_requests_total{method="GET",route="/health",status="200"}' in body
    assert "stockpilot_http_request_duration_seconds_bucket" in body
    assert "stockpilot_low_stock_items 1.0" in body
