def test_receiving_stock_increases_quantity(client, make_item):
    item = make_item(quantity=10)
    response = client.post(f"/api/items/{item['id']}/adjust", json={"delta": 15, "reason": "PO-7"})
    assert response.status_code == 200
    assert response.json()["quantity"] == 25


def test_issuing_stock_decreases_quantity(client, make_item):
    item = make_item(quantity=10)
    response = client.post(f"/api/items/{item['id']}/adjust", json={"delta": -4})
    assert response.status_code == 200
    assert response.json()["quantity"] == 6


def test_cannot_issue_more_than_is_in_stock(client, make_item):
    item = make_item(quantity=3)
    response = client.post(f"/api/items/{item['id']}/adjust", json={"delta": -4})
    assert response.status_code == 409
    assert "Only 3 in stock" in response.json()["detail"]
    assert client.get(f"/api/items/{item['id']}").json()["quantity"] == 3


def test_adjusting_by_zero_is_rejected(client, make_item):
    item = make_item()
    assert client.post(f"/api/items/{item['id']}/adjust", json={"delta": 0}).status_code == 422


def test_adjusting_missing_item_returns_404(client):
    assert client.post("/api/items/9999/adjust", json={"delta": 1}).status_code == 404


def test_adjustment_can_change_stock_status(client, make_item):
    item = make_item(quantity=12, reorder_level=10)
    assert item["stock_status"] == "in_stock"
    body = client.post(f"/api/items/{item['id']}/adjust", json={"delta": -5}).json()
    assert body["stock_status"] == "low_stock"
    body = client.post(f"/api/items/{item['id']}/adjust", json={"delta": -7}).json()
    assert body["stock_status"] == "out_of_stock"


def test_creating_item_with_stock_writes_opening_balance(client, make_item):
    make_item(sku="OPEN-1", name="Opening", quantity=30)
    movements = client.get("/api/movements").json()
    assert len(movements) == 1
    assert movements[0]["delta"] == 30
    assert movements[0]["quantity_after"] == 30
    assert movements[0]["reason"] == "Initial stock"
    assert movements[0]["item_sku"] == "OPEN-1"
    assert movements[0]["item_name"] == "Opening"


def test_creating_item_without_stock_writes_no_movement(client, make_item):
    make_item(quantity=0)
    assert client.get("/api/movements").json() == []


def test_movements_are_listed_newest_first_with_default_reasons(client, make_item):
    item = make_item(quantity=10)
    client.post(f"/api/items/{item['id']}/adjust", json={"delta": 5})
    client.post(f"/api/items/{item['id']}/adjust", json={"delta": -2})
    movements = client.get("/api/movements").json()
    assert [(m["delta"], m["quantity_after"]) for m in movements] == [(-2, 13), (5, 15), (10, 10)]
    assert movements[0]["reason"] == "Stock issued"
    assert movements[1]["reason"] == "Stock received"


def test_movements_respect_limit(client, make_item):
    item = make_item(quantity=1)
    for _ in range(4):
        client.post(f"/api/items/{item['id']}/adjust", json={"delta": 1})
    assert len(client.get("/api/movements", params={"limit": 2}).json()) == 2
    assert client.get("/api/movements", params={"limit": 0}).status_code == 422


def test_editing_quantity_directly_is_logged_as_a_movement(client, make_item):
    item = make_item(quantity=10)
    client.put(f"/api/items/{item['id']}", json={"quantity": 7})
    latest = client.get("/api/movements").json()[0]
    assert latest["delta"] == -3
    assert latest["quantity_after"] == 7
    assert latest["reason"] == "Manual edit"


def test_editing_other_fields_does_not_write_a_movement(client, make_item):
    item = make_item(quantity=10)
    client.put(f"/api/items/{item['id']}", json={"name": "Renamed"})
    assert len(client.get("/api/movements").json()) == 1  # only the opening balance
