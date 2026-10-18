"""create items table

Revision ID: 0001
Revises:
Create Date: 2026-10-08 20:10:00
"""
from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "items",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("sku", sa.String(length=40), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("description", sa.Text(), nullable=False, server_default=""),
        sa.Column("category", sa.String(length=60), nullable=False, server_default="General"),
        sa.Column("quantity", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("reorder_level", sa.Integer(), nullable=False, server_default="10"),
        sa.Column("unit_price", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("supplier", sa.String(length=100), nullable=True),
        sa.Column("location", sa.String(length=50), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()
        ),
        sa.CheckConstraint("quantity >= 0", name="ck_items_quantity_non_negative"),
    )
    op.create_index("ix_items_sku", "items", ["sku"], unique=True)
    op.create_index("ix_items_category", "items", ["category"])


def downgrade() -> None:
    op.drop_index("ix_items_category", table_name="items")
    op.drop_index("ix_items_sku", table_name="items")
    op.drop_table("items")
