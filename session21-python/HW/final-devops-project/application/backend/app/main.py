import json
import logging
import time

from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from prometheus_client import Gauge
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import func, select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from .config import settings
from .db import get_db
from .models import Task
from .schemas import StatsOut, TaskCreate, TaskOut, TaskUpdate

logging.basicConfig(level=settings.log_level.upper(), format="%(message)s")
log = logging.getLogger("taskboard")

app = FastAPI(title=settings.app_name, version=settings.app_version)
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["GET", "POST", "PUT", "DELETE"], allow_headers=["*"]
)

# /metrics: request count/latency per handler (instrumentator) + one business metric.
Instrumentator(excluded_handlers=["/metrics", "/health", "/ready"]).instrument(app).expose(
    app, endpoint="/metrics", include_in_schema=False
)
TASKS_GAUGE = Gauge("taskboard_tasks", "Number of tasks per status", ["status"])
BUILD_INFO = Gauge("taskboard_build_info", "Build information", ["version", "env"])
BUILD_INFO.labels(version=settings.app_version, env=settings.app_env).set(1)


@app.middleware("http")
async def access_log(request: Request, call_next):
    """One JSON log line per request, so `kubectl logs` output is easy to grep."""
    start = time.perf_counter()
    response = await call_next(request)
    if request.url.path not in ("/health", "/ready", "/metrics"):
        log.info(json.dumps({
            "method": request.method,
            "path": request.url.path,
            "status": response.status_code,
            "duration_ms": round((time.perf_counter() - start) * 1000, 2),
        }))
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-App-Version"] = settings.app_version
    return response


@app.get("/")
def root():
    return {"service": settings.app_name, "version": settings.app_version, "env": settings.app_env, "docs": "/docs"}


@app.get("/health")
def health():
    """Liveness: the process is up. Never touches the database."""
    return {"status": "UP"}


@app.get("/ready")
def ready(db: Session = Depends(get_db)):
    """Readiness: only READY when the database answers."""
    try:
        db.execute(select(func.count(Task.id)))
    except SQLAlchemyError as exc:
        log.warning(json.dumps({"event": "readiness_failed", "error": exc.__class__.__name__}))
        return JSONResponse(status_code=503, content={"status": "NOT_READY", "reason": "database unavailable"})
    return {"status": "READY"}


@app.get("/api/tasks", response_model=list[TaskOut])
def list_tasks(db: Session = Depends(get_db)):
    return list(db.scalars(select(Task).order_by(Task.id.desc())))


@app.get("/api/tasks/stats", response_model=StatsOut)
def stats(db: Session = Depends(get_db)):
    rows = db.execute(select(Task.status, func.count(Task.id)).group_by(Task.status)).all()
    counts = {s: c for s, c in rows}
    for s in ("TODO", "IN_PROGRESS", "DONE"):
        TASKS_GAUGE.labels(status=s).set(counts.get(s, 0))
    return StatsOut(
        total=sum(counts.values()),
        todo=counts.get("TODO", 0),
        inProgress=counts.get("IN_PROGRESS", 0),
        done=counts.get("DONE", 0),
    )


@app.get("/api/tasks/{task_id}", response_model=TaskOut)
def get_task(task_id: int, db: Session = Depends(get_db)):
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.post("/api/tasks", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
def create_task(payload: TaskCreate, db: Session = Depends(get_db)):
    task = Task(**payload.model_dump())
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@app.put("/api/tasks/{task_id}", response_model=TaskOut)
def update_task(task_id: int, payload: TaskUpdate, db: Session = Depends(get_db)):
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(task, key, value)
    db.commit()
    db.refresh(task)
    return task


@app.delete("/api/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()
