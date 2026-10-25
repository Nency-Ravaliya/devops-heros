import logging
import time

from fastapi import Depends, FastAPI, HTTPException, Response, status
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import Counter
from sqlalchemy import func, select, text
from sqlalchemy.orm import Session

from . import metrics, models, schemas
from .config import settings
from .db import get_db

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("studytrack")

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="StudyTrack keeps a log of study sessions per subject and shows progress against a daily goal.",
)

if settings.cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[o.strip() for o in settings.cors_origins.split(",") if o.strip()],
        allow_methods=["GET", "POST", "PUT", "DELETE"],
        allow_headers=["Content-Type"],
    )

# Prometheus: request counter + latency histogram from app/metrics.py (exposed at /metrics)
# plus two business counters so the Grafana panel shows something that is really ours.
metrics.install(app)

ENTRIES_CREATED = Counter(
    "studytrack_entries_created_total", "Study entries created through the API", ["subject"]
)
MINUTES_LOGGED = Counter("studytrack_minutes_logged_total", "Study minutes logged through the API")

STARTED_AT = time.time()


# ---------------------------------------------------------------- health / readiness
@app.get("/", tags=["meta"])
def root():
    return {
        "app": settings.app_name,
        "version": settings.app_version,
        "environment": settings.app_env,
        "docs": "/docs",
        "uptime_seconds": round(time.time() - STARTED_AT, 1),
    }


@app.get("/health", tags=["meta"])
def health():
    """Liveness: the process is up and can answer HTTP. No dependencies checked on purpose."""
    return {"status": "ok"}


@app.get("/ready", tags=["meta"])
def ready(response: Response, db: Session = Depends(get_db)):
    """Readiness: only READY when the database answers, so traffic is not routed to a pod
    whose DB connection is broken."""
    try:
        db.execute(text("SELECT 1"))
    except Exception as exc:  # noqa: BLE001 - any DB failure means not ready
        log.warning("readiness check failed: %s", exc)
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "not_ready", "database": "down"}
    return {"status": "ready", "database": "up"}


# ---------------------------------------------------------------- study entries CRUD
def _get_or_404(db: Session, entry_id: int) -> models.StudyEntry:
    entry = db.get(models.StudyEntry, entry_id)
    if entry is None:
        raise HTTPException(status_code=404, detail=f"study entry {entry_id} not found")
    return entry


@app.get("/api/entries", response_model=list[schemas.StudyEntryOut], tags=["entries"])
def list_entries(
    subject: str | None = None,
    status_filter: schemas.Status | None = None,
    db: Session = Depends(get_db),
):
    stmt = select(models.StudyEntry).order_by(models.StudyEntry.created_at.desc(), models.StudyEntry.id.desc())
    if subject:
        stmt = stmt.where(models.StudyEntry.subject == subject)
    if status_filter:
        stmt = stmt.where(models.StudyEntry.status == status_filter)
    return list(db.scalars(stmt))


@app.get("/api/entries/summary", response_model=schemas.Summary, tags=["entries"])
def summary(db: Session = Depends(get_db)):
    total_entries = db.scalar(select(func.count(models.StudyEntry.id))) or 0
    total_minutes = db.scalar(select(func.coalesce(func.sum(models.StudyEntry.minutes), 0))) or 0
    done_minutes = (
        db.scalar(
            select(func.coalesce(func.sum(models.StudyEntry.minutes), 0)).where(models.StudyEntry.status == "done")
        )
        or 0
    )
    by_status = {
        s: c
        for s, c in db.execute(
            select(models.StudyEntry.status, func.count(models.StudyEntry.id)).group_by(models.StudyEntry.status)
        )
    }
    by_subject = [
        schemas.SubjectTotal(subject=s, minutes=int(m), entries=int(c))
        for s, m, c in db.execute(
            select(
                models.StudyEntry.subject,
                func.coalesce(func.sum(models.StudyEntry.minutes), 0),
                func.count(models.StudyEntry.id),
            )
            .group_by(models.StudyEntry.subject)
            .order_by(func.sum(models.StudyEntry.minutes).desc())
        )
    ]
    return schemas.Summary(
        total_entries=int(total_entries),
        total_minutes=int(total_minutes),
        done_minutes=int(done_minutes),
        daily_goal_minutes=settings.daily_goal_minutes,
        goal_reached=int(done_minutes) >= settings.daily_goal_minutes,
        by_status=by_status,
        by_subject=by_subject,
    )


@app.get("/api/entries/{entry_id}", response_model=schemas.StudyEntryOut, tags=["entries"])
def get_entry(entry_id: int, db: Session = Depends(get_db)):
    return _get_or_404(db, entry_id)


@app.post("/api/entries", response_model=schemas.StudyEntryOut, status_code=201, tags=["entries"])
def create_entry(payload: schemas.StudyEntryCreate, db: Session = Depends(get_db)):
    entry = models.StudyEntry(**payload.model_dump())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    ENTRIES_CREATED.labels(subject=entry.subject).inc()
    MINUTES_LOGGED.inc(entry.minutes)
    log.info("created entry id=%s subject=%s minutes=%s", entry.id, entry.subject, entry.minutes)
    return entry


@app.put("/api/entries/{entry_id}", response_model=schemas.StudyEntryOut, tags=["entries"])
def update_entry(entry_id: int, payload: schemas.StudyEntryUpdate, db: Session = Depends(get_db)):
    entry = _get_or_404(db, entry_id)
    changes = payload.model_dump(exclude_unset=True)
    if not changes:
        raise HTTPException(status_code=422, detail="no fields to update")
    for field, value in changes.items():
        setattr(entry, field, value)
    db.commit()
    db.refresh(entry)
    return entry


@app.delete("/api/entries/{entry_id}", status_code=204, tags=["entries"])
def delete_entry(entry_id: int, db: Session = Depends(get_db)):
    entry = _get_or_404(db, entry_id)
    db.delete(entry)
    db.commit()
    return Response(status_code=204)
