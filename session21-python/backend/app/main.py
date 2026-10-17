from collections import defaultdict
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from .config import settings
from .db import Base, engine, get_db
from .models import Exercise, Workout, WorkoutSet
from .schemas import (ExerciseCreate, ExerciseOut, ExerciseUpdate, PersonalRecord, ProgressPoint,
                      SetIn, SetOut, StatsOut, WorkoutCreate, WorkoutOut, WorkoutUpdate)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Production containers run Alembic before Uvicorn; create_all keeps tests self-contained.
    Base.metadata.create_all(bind=engine)
    yield

app = FastAPI(title=settings.app_name, version="2.0.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


# ---- helpers -----------------------------------------------------------------
def est_1rm(weight_kg: float, reps: int) -> float:
    """Epley estimate of a one-rep max."""
    return round(weight_kg if reps == 1 else weight_kg * (1 + reps / 30), 1)

def as_utc(dt: datetime) -> datetime:
    # SQLite returns naive datetimes; treat them as UTC
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)

def workout_out(w: Workout) -> WorkoutOut:
    sets = [SetOut(id=s.id, position=s.position, exercise_id=s.exercise_id, exercise_name=s.exercise.name,
                   reps=s.reps, weight_kg=s.weight_kg, rpe=s.rpe, est_1rm_kg=est_1rm(s.weight_kg, s.reps)) for s in w.sets]
    return WorkoutOut(id=w.id, title=w.title, notes=w.notes, performed_at=as_utc(w.performed_at), duration_min=w.duration_min,
                      sets=sets, total_sets=len(sets), volume_kg=round(sum(s.reps * s.weight_kg for s in w.sets), 1))

def build_sets(db: Session, sets: list[SetIn]) -> list[WorkoutSet]:
    ids = {s.exercise_id for s in sets}
    found = set(db.scalars(select(Exercise.id).where(Exercise.id.in_(ids))))
    if missing := ids - found:
        raise HTTPException(status_code=422, detail=f"Unknown exercise id(s): {sorted(missing)}")
    return [WorkoutSet(position=i + 1, **s.model_dump()) for i, s in enumerate(sets)]

def get_or_404(db: Session, model, obj_id: int, name: str):
    obj = db.get(model, obj_id)
    if not obj:
        raise HTTPException(status_code=404, detail=f"{name} not found")
    return obj

def load_workouts(db: Session):
    return db.scalars(select(Workout).options(selectinload(Workout.sets).selectinload(WorkoutSet.exercise))
                      .order_by(Workout.performed_at.desc(), Workout.id.desc())).all()


# ---- service -----------------------------------------------------------------
@app.get("/")
def root():
    return {"service": settings.app_name, "version": "2.0.0", "docs": "/docs"}

@app.get("/health")
def health():
    return {"status": "UP"}

@app.get("/ready")
def ready(db: Session = Depends(get_db)):
    db.execute(select(func.count(Exercise.id)))
    return {"status": "READY"}


# ---- exercises ---------------------------------------------------------------
@app.get("/api/exercises", response_model=list[ExerciseOut])
def list_exercises(db: Session = Depends(get_db)):
    return db.scalars(select(Exercise).order_by(Exercise.muscle_group, Exercise.name)).all()

@app.post("/api/exercises", response_model=ExerciseOut, status_code=status.HTTP_201_CREATED)
def create_exercise(payload: ExerciseCreate, db: Session = Depends(get_db)):
    exercise = Exercise(**payload.model_dump())
    db.add(exercise)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="An exercise with this name already exists")
    db.refresh(exercise)
    return exercise

@app.put("/api/exercises/{exercise_id}", response_model=ExerciseOut)
def update_exercise(exercise_id: int, payload: ExerciseUpdate, db: Session = Depends(get_db)):
    exercise = get_or_404(db, Exercise, exercise_id, "Exercise")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(exercise, key, value)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="An exercise with this name already exists")
    db.refresh(exercise)
    return exercise

@app.delete("/api/exercises/{exercise_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_exercise(exercise_id: int, db: Session = Depends(get_db)):
    exercise = get_or_404(db, Exercise, exercise_id, "Exercise")
    if db.scalar(select(func.count(WorkoutSet.id)).where(WorkoutSet.exercise_id == exercise_id)):
        raise HTTPException(status_code=409, detail="Exercise is used in logged workouts")
    db.delete(exercise)
    db.commit()

@app.get("/api/exercises/{exercise_id}/progress", response_model=list[ProgressPoint])
def exercise_progress(exercise_id: int, db: Session = Depends(get_db)):
    get_or_404(db, Exercise, exercise_id, "Exercise")
    points = []
    for w in reversed(load_workouts(db)):  # oldest first, for charting
        sets = [s for s in w.sets if s.exercise_id == exercise_id]
        if sets:
            points.append(ProgressPoint(workout_id=w.id, performed_at=as_utc(w.performed_at),
                                        top_weight_kg=max(s.weight_kg for s in sets),
                                        best_est_1rm_kg=max(est_1rm(s.weight_kg, s.reps) for s in sets),
                                        volume_kg=round(sum(s.reps * s.weight_kg for s in sets), 1)))
    return points


# ---- workouts ----------------------------------------------------------------
@app.get("/api/workouts", response_model=list[WorkoutOut])
def list_workouts(db: Session = Depends(get_db)):
    return [workout_out(w) for w in load_workouts(db)]

@app.get("/api/workouts/{workout_id}", response_model=WorkoutOut)
def get_workout(workout_id: int, db: Session = Depends(get_db)):
    return workout_out(get_or_404(db, Workout, workout_id, "Workout"))

@app.post("/api/workouts", response_model=WorkoutOut, status_code=status.HTTP_201_CREATED)
def create_workout(payload: WorkoutCreate, db: Session = Depends(get_db)):
    data = payload.model_dump(exclude={"sets"}, exclude_none=True)
    workout = Workout(**data, sets=build_sets(db, payload.sets))
    db.add(workout)
    db.commit()
    db.refresh(workout)
    return workout_out(workout)

@app.put("/api/workouts/{workout_id}", response_model=WorkoutOut)
def update_workout(workout_id: int, payload: WorkoutUpdate, db: Session = Depends(get_db)):
    workout = get_or_404(db, Workout, workout_id, "Workout")
    changes = payload.model_dump(exclude_unset=True, exclude={"sets"})
    for key, value in changes.items():
        setattr(workout, key, value)
    if payload.sets is not None:
        workout.sets = build_sets(db, payload.sets)
    db.commit()
    db.refresh(workout)
    return workout_out(workout)

@app.delete("/api/workouts/{workout_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_workout(workout_id: int, db: Session = Depends(get_db)):
    db.delete(get_or_404(db, Workout, workout_id, "Workout"))
    db.commit()


# ---- analytics ---------------------------------------------------------------
@app.get("/api/stats", response_model=StatsOut)
def stats(db: Session = Depends(get_db)):
    workouts = load_workouts(db)
    now = datetime.now(timezone.utc)
    week, month = now - timedelta(days=7), now - timedelta(days=30)
    recent = [w for w in workouts if as_utc(w.performed_at) >= week]
    by_group: dict[str, float] = defaultdict(float)
    records: dict[int, PersonalRecord] = {}
    for w in workouts:
        for s in w.sets:
            if as_utc(w.performed_at) >= month:
                by_group[s.exercise.muscle_group] += s.reps * s.weight_kg
            e1rm = est_1rm(s.weight_kg, s.reps)
            best = records.get(s.exercise_id)
            if best is None or e1rm > best.est_1rm_kg:
                records[s.exercise_id] = PersonalRecord(
                    exercise_id=s.exercise_id, exercise=s.exercise.name, muscle_group=s.exercise.muscle_group,
                    best_weight_kg=s.weight_kg, best_set=f"{s.weight_kg:g} kg x {s.reps}", est_1rm_kg=e1rm,
                    achieved_at=as_utc(w.performed_at))
    volume = lambda ws: round(sum(s.reps * s.weight_kg for w in ws for s in w.sets), 1)
    return StatsOut(
        total_workouts=len(workouts),
        workouts_last_7_days=len(recent),
        volume_last_7_days_kg=volume(recent),
        total_volume_kg=volume(workouts),
        total_sets=sum(len(w.sets) for w in workouts),
        volume_by_muscle_group_30d={k: round(v, 1) for k, v in sorted(by_group.items(), key=lambda kv: -kv[1])},
        personal_records=sorted(records.values(), key=lambda r: -r.est_1rm_kg),
    )
