from alembic import op
import sqlalchemy as sa

revision = "0001_create_labs"
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        "labs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("objective", sa.Text(), nullable=False, server_default=""),
        sa.Column("tool", sa.String(length=60), nullable=False, server_default="Kubernetes"),
        sa.Column("difficulty", sa.String(length=20), nullable=False, server_default="BEGINNER"),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="PLANNED"),
        sa.Column("owner", sa.String(length=120), nullable=False, server_default="Anshal Kumar"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

def downgrade():
    op.drop_table("labs")
