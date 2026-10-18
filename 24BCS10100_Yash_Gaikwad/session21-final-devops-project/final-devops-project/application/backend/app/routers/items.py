from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import and_, func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Item, StockMovement
from app.schemas import (
    InventoryStats,
    ItemCreate,
    ItemOut,
    ItemUpdate,
    StockAdjustment,
    StockStatus,
)

router = APIRouter(prefix="/api/items", tags=["items"])


def _get_or_404(db: Session, item_id: int) -> Item:
    item = db.get(Item, item_id)
    if item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
    return item


def _ensure_sku_free(db: Session, sku: str, ignore_id: int | None = None) -> None:
    query = select(Item.id).where(Item.sku == sku)
    if ignore_id is not None:
        query = query.where(Item.id != ignore_id)
    if db.scalar(query) is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, detail=f"SKU {sku} already exists")


def _record_movement(db: Session, item: Item, delta: int, reason: str) -> None:
    db.add(StockMovement(item=item, delta=delta, quantity_after=item.quantity, reason=reason))


def _commit(db: Session) -> None:
    try:
        db.commit()
    except IntegrityError:
        # two requests raced for the same SKU: the unique index is the real guard
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, detail="SKU already exists")


@router.get("", response_model=list[ItemOut])
def list_items(
    stock: StockStatus | None = Query(default=None, description="Filter by stock level"),
    category: str | None = None,
    q: str | None = Query(default=None, description="Search in name and SKU"),
    db: Session = Depends(get_db),
):
    query = select(Item).order_by(Item.name, Item.id)
    if stock == "out_of_stock":
        query = query.where(Item.quantity <= 0)
    elif stock == "low_stock":
        query = query.where(and_(Item.quantity > 0, Item.quantity <= Item.reorder_level))
    elif stock == "in_stock":
        query = query.where(Item.quantity > Item.reorder_level)
    if category:
        query = query.where(Item.category == category)
    if q:
        pattern = f"%{q.strip()}%"
        query = query.where(or_(Item.name.ilike(pattern), Item.sku.ilike(pattern)))
    return db.scalars(query).all()


# declared before "/{item_id}" so "stats" is not parsed as an item id
@router.get("/stats", response_model=InventoryStats)
def inventory_stats(db: Session = Depends(get_db)):
    total_items, total_units, total_value, categories = db.execute(
        select(
            func.count(Item.id),
            func.coalesce(func.sum(Item.quantity), 0),
            func.coalesce(func.sum(Item.quantity * Item.unit_price), 0),
            func.count(func.distinct(Item.category)),
        )
    ).one()
    low_stock = db.scalar(
        select(func.count()).where(and_(Item.quantity > 0, Item.quantity <= Item.reorder_level))
    )
    out_of_stock = db.scalar(select(func.count()).where(Item.quantity <= 0))
    return InventoryStats(
        total_items=total_items,
        total_units=int(total_units),
        total_value=float(total_value),
        low_stock=low_stock or 0,
        out_of_stock=out_of_stock or 0,
        categories=categories,
    )


@router.get("/{item_id}", response_model=ItemOut)
def get_item(item_id: int, db: Session = Depends(get_db)):
    return _get_or_404(db, item_id)


@router.post("", response_model=ItemOut, status_code=status.HTTP_201_CREATED)
def create_item(payload: ItemCreate, db: Session = Depends(get_db)):
    _ensure_sku_free(db, payload.sku)
    item = Item(**payload.model_dump())
    db.add(item)
    if item.quantity > 0:
        _record_movement(db, item, item.quantity, "Initial stock")
    _commit(db)
    db.refresh(item)
    return item


@router.put("/{item_id}", response_model=ItemOut)
def update_item(item_id: int, payload: ItemUpdate, db: Session = Depends(get_db)):
    item = _get_or_404(db, item_id)
    changes = payload.model_dump(exclude_unset=True)
    if "sku" in changes and changes["sku"] is not None:
        _ensure_sku_free(db, changes["sku"], ignore_id=item.id)

    old_quantity = item.quantity
    for field, value in changes.items():
        # only supplier / location may be cleared; null for a required column is ignored
        if value is None and field not in ("supplier", "location"):
            continue
        setattr(item, field, value)
    if item.quantity != old_quantity:
        _record_movement(db, item, item.quantity - old_quantity, "Manual edit")
    _commit(db)
    db.refresh(item)
    return item


@router.post("/{item_id}/adjust", response_model=ItemOut)
def adjust_stock(item_id: int, payload: StockAdjustment, db: Session = Depends(get_db)):
    """Receive (+) or issue (-) stock and write the change to the stock ledger."""
    item = _get_or_404(db, item_id)
    new_quantity = item.quantity + payload.delta
    if new_quantity < 0:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            detail=f"Only {item.quantity} in stock, cannot issue {-payload.delta}",
        )
    item.quantity = new_quantity
    default_reason = "Stock received" if payload.delta > 0 else "Stock issued"
    _record_movement(db, item, payload.delta, payload.reason or default_reason)
    _commit(db)
    db.refresh(item)
    return item


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item(item_id: int, db: Session = Depends(get_db)):
    item = _get_or_404(db, item_id)
    db.delete(item)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
