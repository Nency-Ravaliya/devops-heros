import logging
import os
import time
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Query, Response
from fastapi.responses import JSONResponse
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from sqlalchemy import func, select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Ticket
from app.schemas import Priority, TicketList, TicketRead, TicketStats, TicketStatus, TicketWrite

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("queuedesk")
app = FastAPI(title="QueueDesk API", version="1.0.0")
Db = Annotated[Session, Depends(get_db)]
REQUESTS = Counter("queuedesk_http_requests_total", "HTTP responses", ["method", "route", "status"])
LATENCY = Histogram(
    "queuedesk_http_request_duration_seconds",
    "HTTP latency",
    ["method", "route"],
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5),
)


@app.middleware("http")
async def metrics(request, call_next):
    start = time.perf_counter()
    status = 500
    try:
        response = await call_next(request)
        status = response.status_code
        return response
    finally:
        route = request.scope.get("route")
        path = route.path if route else "unmatched"
        if path not in ("/metrics", "/health", "/ready"):
            REQUESTS.labels(request.method, path, str(status)).inc()
            LATENCY.labels(request.method, path).observe(time.perf_counter() - start)


@app.get("/")
def root():
    return {"application": "QueueDesk", "version": os.getenv("APP_VERSION", "development")}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/ready")
def ready(db: Db):
    try:
        db.execute(select(Ticket.id).limit(1))
    except SQLAlchemyError:
        logger.exception("Database readiness check failed")
        return JSONResponse(status_code=503, content={"status": "not_ready"})
    return {"status": "ready"}


@app.get("/metrics", include_in_schema=False)
def prometheus_metrics():
    return Response(generate_latest(), headers={"Content-Type": CONTENT_TYPE_LATEST})


@app.get("/api/tickets/stats", response_model=TicketStats)
def stats(db: Db):
    counts = dict(db.execute(select(Ticket.status, func.count()).group_by(Ticket.status)).all())
    urgent = db.scalar(
        select(func.count())
        .select_from(Ticket)
        .where(Ticket.priority == "urgent", Ticket.status != "resolved")
    )
    return {
        "total": sum(counts.values()),
        "open": counts.get("open", 0),
        "in_progress": counts.get("in_progress", 0),
        "resolved": counts.get("resolved", 0),
        "urgent": urgent,
    }


@app.get("/api/tickets", response_model=TicketList)
def list_tickets(
    db: Db,
    status: TicketStatus | None = None,
    priority: Priority | None = None,
    q: str = Query(default="", max_length=160),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    query = select(Ticket)
    if status:
        query = query.where(Ticket.status == status)
    if priority:
        query = query.where(Ticket.priority == priority)
    if q.strip():
        query = query.where(Ticket.title.icontains(q.strip(), autoescape=True))
    total = db.scalar(select(func.count()).select_from(query.subquery()))
    items = db.scalars(
        query.order_by(Ticket.created_at.desc(), Ticket.id.desc()).offset(offset).limit(limit)
    ).all()
    return {"items": items, "total": total, "limit": limit, "offset": offset}


def find_ticket(ticket_id: int, db: Session):
    ticket = db.get(Ticket, ticket_id)
    if ticket is None:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return ticket


@app.get("/api/tickets/{ticket_id}", response_model=TicketRead)
def get_ticket(ticket_id: int, db: Db):
    return find_ticket(ticket_id, db)


@app.post("/api/tickets", response_model=TicketRead, status_code=201)
def create_ticket(payload: TicketWrite, db: Db):
    ticket = Ticket(**payload.model_dump())
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    return ticket


@app.put("/api/tickets/{ticket_id}", response_model=TicketRead)
def update_ticket(ticket_id: int, payload: TicketWrite, db: Db):
    ticket = find_ticket(ticket_id, db)
    for key, value in payload.model_dump().items():
        setattr(ticket, key, value)
    db.commit()
    db.refresh(ticket)
    return ticket


@app.delete("/api/tickets/{ticket_id}", status_code=204)
def delete_ticket(ticket_id: int, db: Db):
    db.delete(find_ticket(ticket_id, db))
    db.commit()
    return Response(status_code=204)
