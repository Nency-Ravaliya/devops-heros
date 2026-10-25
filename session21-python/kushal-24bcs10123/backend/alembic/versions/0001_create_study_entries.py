"""create study_entries table

Revision ID: 0001
Revises:
Create Date: 2026-10-07
"""
from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "study_entries",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("subject", sa.String(length=80), nullable=False),
        sa.Column("topic", sa.String(length=200), nullable=False),
        sa.Column("minutes", sa.Integer(), nullable=False, server_default="30"),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="planned"),
        sa.Column("notes", sa.Text(), nullable=False, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_study_entries_subject", "study_entries", ["subject"])
    op.create_index("ix_study_entries_status", "study_entries", ["status"])


def downgrade() -> None:
    op.drop_index("ix_study_entries_status", table_name="study_entries")
    op.drop_index("ix_study_entries_subject", table_name="study_entries")
    op.drop_table("study_entries")
