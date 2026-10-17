from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

MuscleGroup = Literal["CHEST", "BACK", "SHOULDERS", "BICEPS", "TRICEPS", "QUADS", "HAMSTRINGS", "GLUTES", "CALVES", "CORE", "FULL_BODY"]
Equipment = Literal["BARBELL", "DUMBBELL", "MACHINE", "CABLE", "BODYWEIGHT", "KETTLEBELL", "OTHER"]


# ---- Exercises ---------------------------------------------------------------
class ExerciseCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    muscle_group: MuscleGroup
    equipment: Equipment = "BARBELL"

class ExerciseUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    muscle_group: MuscleGroup | None = None
    equipment: Equipment | None = None

class ExerciseOut(ExerciseCreate):
    id: int
    model_config = ConfigDict(from_attributes=True)


# ---- Workouts ----------------------------------------------------------------
class SetIn(BaseModel):
    exercise_id: int
    reps: int = Field(ge=1, le=100)
    weight_kg: float = Field(default=0, ge=0, le=1000)
    rpe: float | None = Field(default=None, ge=1, le=10)

class SetOut(SetIn):
    id: int
    position: int
    exercise_name: str
    est_1rm_kg: float

class WorkoutCreate(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    notes: str = ""
    performed_at: datetime | None = None
    duration_min: int = Field(default=60, ge=1, le=600)
    sets: list[SetIn] = Field(min_length=1)

class WorkoutUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=120)
    notes: str | None = None
    performed_at: datetime | None = None
    duration_min: int | None = Field(default=None, ge=1, le=600)
    sets: list[SetIn] | None = Field(default=None, min_length=1)  # replaces all sets when given

class WorkoutOut(BaseModel):
    id: int
    title: str
    notes: str
    performed_at: datetime
    duration_min: int
    sets: list[SetOut]
    total_sets: int
    volume_kg: float


# ---- Analytics ---------------------------------------------------------------
class PersonalRecord(BaseModel):
    exercise_id: int
    exercise: str
    muscle_group: str
    best_weight_kg: float
    best_set: str
    est_1rm_kg: float
    achieved_at: datetime

class StatsOut(BaseModel):
    total_workouts: int
    workouts_last_7_days: int
    volume_last_7_days_kg: float
    total_volume_kg: float
    total_sets: int
    volume_by_muscle_group_30d: dict[str, float]
    personal_records: list[PersonalRecord]

class ProgressPoint(BaseModel):
    workout_id: int
    performed_at: datetime
    top_weight_kg: float
    best_est_1rm_kg: float
    volume_kg: float
