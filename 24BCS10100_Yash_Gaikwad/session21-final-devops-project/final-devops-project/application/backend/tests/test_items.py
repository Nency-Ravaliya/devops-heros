import pytest


def test_list_items_starts_empty(client):
    response = client.get("/api/items")
    assert response.status_code == 200
    assert response.json() == []


def test_create_item_applies_defaults(client):
    response = client.post("/api/items", json={"sku": "ab-1", "name": "Bolt"})
    assert response.status_code == 201
    body = response.json()
    assert body["id"] > 0
    assert body["sku"] == "AB-1"  # SKUs are normalised to upper case
    assert body["category"] == "General"
    assert body["quantity"] == 0
    assert body["reorder_level"] == 10
    assert body["unit_price"] == 0
    assert body["supplier"] is None
    assert body["stock_status"] == "out_of_stock"


def test_create_item_returns_price_as_number(client):
    body = client.post("/api/items", json={"sku": "P-1", "name": "Pen", "unit_price": "12.50"}).json()
    assert body["unit_price"] == 12.5


def test_create_item_rejects_duplicate_sku(client, make_item):
    make_item(sku="DUP-1")
    response = client.post("/api/items", json={"sku": "dup-1", "name": "Other"})
    assert response.status_code == 409
    assert "already exists" in response.json()["detail"]


@pytest.mark.parametrize(
    "payload",
    [
        {"sku": "", "name": "x"},
        {"sku": "bad sku!", "name": "x"},
        {"sku": "OK-1", "name": ""},
        {"sku": "OK-1", "name": "x", "quantity": -1},
        {"sku": "OK-1", "name": "x", "unit_price": -0.01},
        {"sku": "OK-1", "name": "x", "unit_price": "1.234"},
    ],
)
def test_create_item_validates_input(client, payload):
    assert client.post("/api/items", json=payload).status_code == 422


def test_get_item_by_id(client, make_item):
    created = make_item(name="Read me")
    response = client.get(f"/api/items/{created['id']}")
    assert response.status_code == 200
    assert response.json()["name"] == "Read me"


def test_get_missing_item_returns_404(client):
    response = client.get("/api/items/9999")
    assert response.status_code == 404
    assert response.json()["detail"] == "Item not found"


def test_list_is_sorted_by_name(client, make_item):
    make_item(name="Zip ties")
    make_item(name="Anchors")
    assert [i["name"] for i in client.get("/api/items").json()] == ["Anchors", "Zip ties"]


def test_stock_status_boundaries(client, make_item):
    make_item(name="plenty", quantity=11, reorder_level=10)
    make_item(name="at-reorder-level", quantity=10, reorder_level=10)
    make_item(name="empty", quantity=0, reorder_level=10)
    statuses = {i["name"]: i["stock_status"] for i in client.get("/api/items").json()}
    assert statuses == {
        "plenty": "in_stock",
        "at-reorder-level": "low_stock",
        "empty": "out_of_stock",
    }


@pytest.mark.parametrize(
    "stock,expected",
    [
        ("in_stock", ["plenty"]),
        ("low_stock", ["running-low"]),
        ("out_of_stock", ["empty"]),
    ],
)
def test_list_can_filter_by_stock_status(client, make_item, stock, expected):
    make_item(name="plenty", quantity=100)
    make_item(name="running-low", quantity=3)
    make_item(name="empty", quantity=0)
    response = client.get("/api/items", params={"stock": stock})
    assert response.status_code == 200
    assert [i["name"] for i in response.json()] == expected


def test_list_can_filter_by_category_and_search(client, make_item):
    make_item(name="Hammer", sku="TL-1", category="Tools")
    make_item(name="Paper", sku="OF-1", category="Office")
    assert [i["name"] for i in client.get("/api/items", params={"category": "Tools"}).json()] == ["Hammer"]
    assert [i["name"] for i in client.get("/api/items", params={"q": "pap"}).json()] == ["Paper"]
    assert [i["name"] for i in client.get("/api/items", params={"q": "tl-1"}).json()] == ["Hammer"]
    assert client.get("/api/items", params={"q": "nothing"}).json() == []


def test_update_item_changes_only_sent_fields(client, make_item):
    created = make_item(name="Original", category="Tools", unit_price=3)
    response = client.put(f"/api/items/{created['id']}", json={"unit_price": 4.75})
    assert response.status_code == 200
    body = response.json()
    assert body["unit_price"] == 4.75
    assert body["name"] == "Original"
    assert body["category"] == "Tools"


def test_update_item_can_clear_optional_fields(client, make_item):
    created = make_item(supplier="Acme", location="A-1")
    body = client.put(f"/api/items/{created['id']}", json={"supplier": None}).json()
    assert body["supplier"] is None
    assert body["location"] == "A-1"


def test_update_item_ignores_null_for_required_fields(client, make_item):
    created = make_item(name="Keep me")
    response = client.put(f"/api/items/{created['id']}", json={"name": None})
    assert response.status_code == 200
    assert response.json()["name"] == "Keep me"


def test_update_item_rejects_sku_owned_by_another_item(client, make_item):
    make_item(sku="TAKEN-1")
    other = make_item(sku="FREE-1")
    response = client.put(f"/api/items/{other['id']}", json={"sku": "taken-1"})
    assert response.status_code == 409


def test_update_item_may_keep_its_own_sku(client, make_item):
    item = make_item(sku="MINE-1")
    response = client.put(f"/api/items/{item['id']}", json={"sku": "mine-1", "name": "Renamed"})
    assert response.status_code == 200
    assert response.json()["name"] == "Renamed"


def test_update_missing_item_returns_404(client):
    assert client.put("/api/items/9999", json={"name": "x"}).status_code == 404


def test_delete_item_removes_it_and_its_ledger(client, make_item):
    created = make_item(quantity=5)
    assert client.delete(f"/api/items/{created['id']}").status_code == 204
    assert client.get(f"/api/items/{created['id']}").status_code == 404
    assert client.get("/api/movements").json() == []


def test_delete_missing_item_returns_404(client):
    assert client.delete("/api/items/9999").status_code == 404


def test_stats_summarise_inventory(client, make_item):
    make_item(category="Tools", quantity=100, reorder_level=10, unit_price=2)  # 200
    make_item(category="Tools", quantity=4, reorder_level=10, unit_price=10)  # 40, low
    make_item(category="Office", quantity=0, reorder_level=5, unit_price=99)  # out
    response = client.get("/api/items/stats")
    assert response.status_code == 200
    assert response.json() == {
        "total_items": 3,
        "total_units": 104,
        "total_value": 240.0,
        "low_stock": 1,
        "out_of_stock": 1,
        "categories": 2,
    }


def test_stats_on_empty_database(client):
    assert client.get("/api/items/stats").json() == {
        "total_items": 0,
        "total_units": 0,
        "total_value": 0.0,
        "low_stock": 0,
        "out_of_stock": 0,
        "categories": 0,
    }
