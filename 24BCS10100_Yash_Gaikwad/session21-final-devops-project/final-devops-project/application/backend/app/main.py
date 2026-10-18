from fastapi import Depends, FastAPI
from fastapi.responses import JSONResponse
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.routers import items, movements

app = FastAPI(
    title="StockPilot API",
    description="Inventory management API used for the DevOps capstone.",
    version="1.0.0",
)

app.include_router(items.router)
app.include_router(movements.router)


@app.get("/", tags=["meta"])
def root():
    return {"service": "stockpilot-backend", "docs": "/docs", "status": "running"}


@app.get("/health", tags=["meta"])
def health():
    """Liveness: the process is up. Deliberately does not touch the database."""
    return {"status": "OK"}


@app.get("/ready", tags=["meta"])
def ready(db: Session = Depends(get_db)):
    """Readiness: can we serve traffic? Verifies database access."""
    try:
        db.execute(text("SELECT 1"))
    except Exception:
        return JSONResponse(status_code=503, content={"status": "NOT_READY"})
    return {"status": "READY"}


# request count / latency histograms at GET /metrics; probes are left out of the stats
Instrumentator(excluded_handlers=["/metrics", "/health", "/ready"]).instrument(app).expose(
    app, endpoint="/metrics", include_in_schema=False
)
