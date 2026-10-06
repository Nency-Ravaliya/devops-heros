import logging
import time
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import Depends, FastAPI, HTTPException, Request, Response, status
from fastapi.responses import FileResponse
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
from sqlalchemy import func, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from . import metrics
from .config import settings
from .db import Base, SessionLocal, engine, get_db
from .models import Item
from .schemas import ItemCreate, ItemOut, ItemUpdate, StockAdjustment, Summary

logging.basicConfig(level=settings.log_level.upper(), format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("stockpilot")

STATIC_DIR = Path(__file__).parent / "static"


_schema_ready = False


def ensure_schema() -> bool:
    """Create tables once the database is reachable (idempotent).

    Called at start-up *and* from /ready. If PostgreSQL is not up yet the pod
    stays alive (liveness OK) but un-ready, instead of crash-looping. A larger
    project would run Alembic migrations as a Helm pre-upgrade hook instead.
    """
    global _schema_ready
    if not _schema_ready:
        Base.metadata.create_all(bind=engine)
        _schema_ready = True
    return _schema_ready


@asynccontextmanager
async def lifespan(_: FastAPI):
    try:
        ensure_schema()
    except Exception as exc:  # pragma: no cover - exercised in k8s only
        log.warning("database not reachable at start-up, will retry from /ready: %s", exc)
    metrics.BUILD_INFO.info({"version": settings.app_version, "env": settings.app_env})
    log.info("StockPilot started env=%s version=%s", settings.app_env, settings.app_version)
    yield


app = FastAPI(title=settings.app_name, version=settings.app_version, lifespan=lifespan)


@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    if request.url.path == "/metrics":
        return await call_next(request)
    start = time.perf_counter()
    metrics.HTTP_IN_PROGRESS.inc()
    status_code = 500
    try:
        response = await call_next(request)
        status_code = response.status_code
        return response
    finally:
        metrics.HTTP_IN_PROGRESS.dec()
        route = request.scope.get("route")
        route_path = getattr(route, "path", "unmatched")
        metrics.HTTP_REQUESTS.labels(request.method, route_path, str(status_code)).inc()
        metrics.HTTP_LATENCY.labels(request.method, route_path).observe(time.perf_counter() - start)


def _to_out(item: Item) -> ItemOut:
    return ItemOut(
        id=item.id,
        sku=item.sku,
        name=item.name,
        location=item.location,
        quantity=item.quantity,
        reorder_level=item.reorder_level,
        unit_price_paise=item.unit_price_paise,
        low_stock=item.quantity <= item.reorder_level,
        updated_at=item.updated_at,
    )


def _get_or_404(db: Session, item_id: int) -> Item:
    item = db.get(Item, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


# ---------------------------------------------------------------- platform --
@app.get("/", include_in_schema=False)
def index():
    return FileResponse(STATIC_DIR / "index.html")


@app.get("/health", tags=["platform"])
def health():
    """Liveness: the process is up and the event loop answers."""
    return {"status": "UP"}


@app.get("/ready", tags=["platform"])
def ready(response: Response):
    """Readiness: we can reach the database, so we can serve traffic."""
    try:
        ensure_schema()
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
    except Exception as exc:  # pragma: no cover - exercised in k8s only
        log.warning("readiness check failed: %s", exc)
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "NOT_READY", "reason": "database unreachable"}
    return {"status": "READY"}


@app.get("/metrics", include_in_schema=False)
def prometheus_metrics():
    try:
        with SessionLocal() as db:
            low = db.scalar(select(func.count(Item.id)).where(Item.quantity <= Item.reorder_level))
            metrics.LOW_STOCK_ITEMS.set(low or 0)
    except Exception:  # pragma: no cover - DB down must not break scraping
        pass
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/api/info", tags=["platform"])
def info():
    return {"service": settings.app_name, "version": settings.app_version, "env": settings.app_env}


# -------------------------------------------------------------- inventory --
@app.get("/api/items", response_model=list[ItemOut], tags=["items"])
def list_items(location: str | None = None, db: Session = Depends(get_db)):
    query = select(Item).order_by(Item.sku)
    if location:
        query = query.where(Item.location == location)
    return [_to_out(i) for i in db.scalars(query)]


@app.get("/api/items/low-stock", response_model=list[ItemOut], tags=["items"])
def low_stock(db: Session = Depends(get_db)):
    query = select(Item).where(Item.quantity <= Item.reorder_level).order_by(Item.quantity)
    return [_to_out(i) for i in db.scalars(query)]


@app.get("/api/summary", response_model=Summary, tags=["items"])
def summary(db: Session = Depends(get_db)):
    items = list(db.scalars(select(Item)))
    return Summary(
        total_items=len(items),
        total_units=sum(i.quantity for i in items),
        low_stock_items=sum(1 for i in items if i.quantity <= i.reorder_level),
        inventory_value_paise=sum(i.quantity * i.unit_price_paise for i in items),
    )


@app.get("/api/items/{item_id}", response_model=ItemOut, tags=["items"])
def get_item(item_id: int, db: Session = Depends(get_db)):
    return _to_out(_get_or_404(db, item_id))


@app.post("/api/items", response_model=ItemOut, status_code=status.HTTP_201_CREATED, tags=["items"])
def create_item(payload: ItemCreate, db: Session = Depends(get_db)):
    data = payload.model_dump()
    if data["reorder_level"] is None:
        data["reorder_level"] = settings.default_reorder_level
    item = Item(**data)
    db.add(item)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail=f"SKU {payload.sku} already exists")
    db.refresh(item)
    return _to_out(item)


@app.put("/api/items/{item_id}", response_model=ItemOut, tags=["items"])
def update_item(item_id: int, payload: ItemUpdate, db: Session = Depends(get_db)):
    item = _get_or_404(db, item_id)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return _to_out(item)


@app.post("/api/items/{item_id}/adjust", response_model=ItemOut, tags=["items"])
def adjust_stock(item_id: int, payload: StockAdjustment, db: Session = Depends(get_db)):
    item = _get_or_404(db, item_id)
    new_qty = item.quantity + payload.delta
    if new_qty < 0:
        raise HTTPException(status_code=422, detail="Insufficient stock")
    item.quantity = new_qty
    db.commit()
    db.refresh(item)
    metrics.STOCK_ADJUSTMENTS.labels("in" if payload.delta >= 0 else "out").inc()
    log.info("stock adjusted sku=%s delta=%d reason=%s", item.sku, payload.delta, payload.reason)
    return _to_out(item)


@app.delete("/api/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["items"])
def delete_item(item_id: int, db: Session = Depends(get_db)):
    item = _get_or_404(db, item_id)
    db.delete(item)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
