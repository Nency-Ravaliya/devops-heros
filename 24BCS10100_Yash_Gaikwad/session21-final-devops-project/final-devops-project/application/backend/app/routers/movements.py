from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import StockMovement
from app.schemas import MovementOut

router = APIRouter(prefix="/api/movements", tags=["movements"])


@router.get("", response_model=list[MovementOut])
def recent_movements(limit: int = Query(default=10, ge=1, le=100), db: Session = Depends(get_db)):
    """Latest stock ledger entries, newest first."""
    rows = db.scalars(select(StockMovement).order_by(StockMovement.id.desc()).limit(limit)).all()
    return [MovementOut.from_movement(row) for row in rows]
