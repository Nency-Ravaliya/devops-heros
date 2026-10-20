"""create items table

Revision ID: 0001_create_items
Revises:
Create Date: 2026-10-16
"""
from alembic import op
import sqlalchemy as sa

revision = "0001_create_items"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "items",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("sku", sa.String(length=32), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("location", sa.String(length=60), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("reorder_level", sa.Integer(), nullable=False),
        sa.Column("unit_price_paise", sa.Integer(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_items_sku", "items", ["sku"], unique=True)


def downgrade():
    op.drop_index("ix_items_sku", table_name="items")
    op.drop_table("items")
