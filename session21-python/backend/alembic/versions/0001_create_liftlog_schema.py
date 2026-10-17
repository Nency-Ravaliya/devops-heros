"""LiftLog schema: exercise library, workouts and sets, plus a starter exercise library."""
from datetime import datetime, timezone

import sqlalchemy as sa
from alembic import op

revision = "0001_create_liftlog_schema"
down_revision = None
branch_labels = None
depends_on = None

STARTER_EXERCISES = [
    ("Barbell Bench Press", "CHEST", "BARBELL"),
    ("Incline Dumbbell Press", "CHEST", "DUMBBELL"),
    ("Cable Fly", "CHEST", "CABLE"),
    ("Deadlift", "BACK", "BARBELL"),
    ("Pull-Up", "BACK", "BODYWEIGHT"),
    ("Barbell Row", "BACK", "BARBELL"),
    ("Lat Pulldown", "BACK", "CABLE"),
    ("Overhead Press", "SHOULDERS", "BARBELL"),
    ("Lateral Raise", "SHOULDERS", "DUMBBELL"),
    ("Barbell Curl", "BICEPS", "BARBELL"),
    ("Hammer Curl", "BICEPS", "DUMBBELL"),
    ("Triceps Pushdown", "TRICEPS", "CABLE"),
    ("Skull Crusher", "TRICEPS", "BARBELL"),
    ("Back Squat", "QUADS", "BARBELL"),
    ("Leg Press", "QUADS", "MACHINE"),
    ("Romanian Deadlift", "HAMSTRINGS", "BARBELL"),
    ("Leg Curl", "HAMSTRINGS", "MACHINE"),
    ("Hip Thrust", "GLUTES", "BARBELL"),
    ("Standing Calf Raise", "CALVES", "MACHINE"),
    ("Plank", "CORE", "BODYWEIGHT"),
    ("Hanging Leg Raise", "CORE", "BODYWEIGHT"),
]


def upgrade():
    exercises = op.create_table(
        "exercises",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=120), nullable=False, unique=True),
        sa.Column("muscle_group", sa.String(length=30), nullable=False),
        sa.Column("equipment", sa.String(length=30), nullable=False, server_default="BARBELL"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "workouts",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False, server_default=""),
        sa.Column("performed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("duration_min", sa.Integer(), nullable=False, server_default="60"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "workout_sets",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("workout_id", sa.Integer(), sa.ForeignKey("workouts.id", ondelete="CASCADE"), nullable=False),
        sa.Column("exercise_id", sa.Integer(), sa.ForeignKey("exercises.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column("reps", sa.Integer(), nullable=False),
        sa.Column("weight_kg", sa.Float(), nullable=False, server_default="0"),
        sa.Column("rpe", sa.Float(), nullable=True),
    )
    op.create_index("ix_workout_sets_workout_id", "workout_sets", ["workout_id"])
    op.create_index("ix_workout_sets_exercise_id", "workout_sets", ["exercise_id"])

    now = datetime.now(timezone.utc)
    op.bulk_insert(exercises, [
        {"name": name, "muscle_group": group, "equipment": equipment, "created_at": now}
        for name, group, equipment in STARTER_EXERCISES
    ])


def downgrade():
    op.drop_table("workout_sets")
    op.drop_table("workouts")
    op.drop_table("exercises")
