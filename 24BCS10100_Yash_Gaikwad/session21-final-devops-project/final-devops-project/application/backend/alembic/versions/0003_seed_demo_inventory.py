"""seed demo inventory

Gives a fresh environment some stock so the dashboard is not empty during demos.
Only inserts when the items table has no rows yet.

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-08 20:20:00
"""
from alembic import op
import sqlalchemy as sa

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None

# sku, name, category, quantity, reorder_level, unit_price, supplier, location
DEMO_ITEMS = [
    ("EL-1001", "Wireless barcode scanner", "Electronics", 42, 15, "89.00", "ScanTech", "A-01"),
    ("EL-1002", "Thermal label printer", "Electronics", 8, 10, "149.50", "ScanTech", "A-02"),
    ("EL-1003", "USB-C docking station", "Electronics", 0, 5, "119.99", "Nimbus Hardware", "A-03"),
    ("OF-2001", "A4 copier paper (500 sheets)", "Office", 320, 100, "4.25", "PaperPlus", "B-07"),
    ("OF-2002", "Ballpoint pens (box of 50)", "Office", 12, 20, "7.80", "PaperPlus", "B-08"),
    ("PK-3001", "Corrugated shipping box (M)", "Packaging", 540, 200, "0.65", "BoxWorks", "C-02"),
    ("PK-3002", "Bubble wrap roll 50 m", "Packaging", 18, 25, "12.40", "BoxWorks", "C-04"),
    ("PK-3003", "Packing tape (6 rolls)", "Packaging", 75, 30, "9.10", "BoxWorks", "C-05"),
    ("SF-4001", "Safety gloves (pair)", "Safety", 160, 50, "2.35", "SafeGear", "D-01"),
    ("SF-4002", "High-visibility vest", "Safety", 0, 15, "6.90", "SafeGear", "D-03"),
]

# sku, delta, reason (applied after the initial stock was recorded)
DEMO_MOVEMENTS = [
    ("EL-1001", -8, "Shipped: order #1042"),
    ("OF-2001", 120, "Received: purchase order PO-311"),
    ("PK-3002", -7, "Shipped: order #1047"),
    ("EL-1003", -5, "Shipped: order #1050"),
]


def upgrade() -> None:
    bind = op.get_bind()
    items = sa.table(
        "items",
        sa.column("id", sa.Integer),
        sa.column("sku", sa.String),
        sa.column("name", sa.String),
        sa.column("category", sa.String),
        sa.column("quantity", sa.Integer),
        sa.column("reorder_level", sa.Integer),
        sa.column("unit_price", sa.Numeric),
        sa.column("supplier", sa.String),
        sa.column("location", sa.String),
    )
    movements = sa.table(
        "stock_movements",
        sa.column("item_id", sa.Integer),
        sa.column("delta", sa.Integer),
        sa.column("quantity_after", sa.Integer),
        sa.column("reason", sa.String),
    )

    if bind.execute(sa.select(sa.func.count()).select_from(items)).scalar():
        return

    final_quantity = {sku: qty for sku, _, _, qty, *_ in DEMO_ITEMS}
    adjustments = {}
    for sku, delta, _ in DEMO_MOVEMENTS:
        adjustments[sku] = adjustments.get(sku, 0) + delta

    # items are stored with their final quantity; the ledger replays how they got there
    op.bulk_insert(
        items,
        [
            {
                "sku": sku,
                "name": name,
                "category": category,
                "quantity": qty,
                "reorder_level": reorder,
                "unit_price": price,
                "supplier": supplier,
                "location": location,
            }
            for sku, name, category, qty, reorder, price, supplier, location in DEMO_ITEMS
        ],
    )

    ids = {row.sku: row.id for row in bind.execute(sa.select(items.c.id, items.c.sku))}
    ledger = []
    for sku, qty in final_quantity.items():
        opening = qty - adjustments.get(sku, 0)
        ledger.append(
            {"item_id": ids[sku], "delta": opening, "quantity_after": opening, "reason": "Initial stock"}
        )
    running = {sku: qty - adjustments.get(sku, 0) for sku, qty in final_quantity.items()}
    for sku, delta, reason in DEMO_MOVEMENTS:
        running[sku] += delta
        ledger.append(
            {"item_id": ids[sku], "delta": delta, "quantity_after": running[sku], "reason": reason}
        )
    op.bulk_insert(movements, ledger)


def downgrade() -> None:
    skus = [row[0] for row in DEMO_ITEMS]
    items = sa.table("items", sa.column("id", sa.Integer), sa.column("sku", sa.String))
    movements = sa.table("stock_movements", sa.column("item_id", sa.Integer))
    demo_ids = sa.select(items.c.id).where(items.c.sku.in_(skus))
    op.execute(movements.delete().where(movements.c.item_id.in_(demo_ids)))
    op.execute(items.delete().where(items.c.sku.in_(skus)))
