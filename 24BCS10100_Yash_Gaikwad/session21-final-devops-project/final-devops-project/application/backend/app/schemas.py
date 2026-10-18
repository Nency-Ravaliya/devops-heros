from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, computed_field, field_serializer, field_validator

StockStatus = Literal["in_stock", "low_stock", "out_of_stock"]

SKU_PATTERN = r"^[A-Za-z0-9][A-Za-z0-9._-]*$"


def stock_status(quantity: int, reorder_level: int) -> StockStatus:
    if quantity <= 0:
        return "out_of_stock"
    if quantity <= reorder_level:
        return "low_stock"
    return "in_stock"


class ItemCreate(BaseModel):
    sku: str = Field(min_length=1, max_length=40, pattern=SKU_PATTERN)
    name: str = Field(min_length=1, max_length=200)
    description: str = Field(default="", max_length=2000)
    category: str = Field(default="General", min_length=1, max_length=60)
    quantity: int = Field(default=0, ge=0, le=10_000_000)
    reorder_level: int = Field(default=10, ge=0, le=10_000_000)
    unit_price: Decimal = Field(default=Decimal("0"), ge=0, max_digits=10, decimal_places=2)
    supplier: str | None = Field(default=None, max_length=100)
    location: str | None = Field(default=None, max_length=50)

    @field_validator("sku")
    @classmethod
    def normalise_sku(cls, value: str) -> str:
        return value.upper()


class ItemUpdate(BaseModel):
    """All fields optional: only the fields that are sent get changed."""

    sku: str | None = Field(default=None, min_length=1, max_length=40, pattern=SKU_PATTERN)
    name: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    category: str | None = Field(default=None, min_length=1, max_length=60)
    quantity: int | None = Field(default=None, ge=0, le=10_000_000)
    reorder_level: int | None = Field(default=None, ge=0, le=10_000_000)
    unit_price: Decimal | None = Field(default=None, ge=0, max_digits=10, decimal_places=2)
    supplier: str | None = Field(default=None, max_length=100)
    location: str | None = Field(default=None, max_length=50)

    @field_validator("sku")
    @classmethod
    def normalise_sku(cls, value: str | None) -> str | None:
        return value.upper() if value else value


class ItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sku: str
    name: str
    description: str
    category: str
    quantity: int
    reorder_level: int
    unit_price: Decimal
    supplier: str | None
    location: str | None
    created_at: datetime
    updated_at: datetime

    @computed_field
    @property
    def stock_status(self) -> StockStatus:
        return stock_status(self.quantity, self.reorder_level)

    # send prices as JSON numbers (12.5) rather than Decimal strings ("12.50")
    @field_serializer("unit_price")
    def serialise_price(self, value: Decimal) -> float:
        return float(value)


class StockAdjustment(BaseModel):
    delta: int = Field(ge=-1_000_000, le=1_000_000, description="+ receive stock, - issue stock")
    reason: str = Field(default="", max_length=200)

    @field_validator("delta")
    @classmethod
    def delta_not_zero(cls, value: int) -> int:
        if value == 0:
            raise ValueError("delta must not be zero")
        return value


class MovementOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    item_id: int
    delta: int
    quantity_after: int
    reason: str
    created_at: datetime
    item_sku: str = ""
    item_name: str = ""

    @classmethod
    def from_movement(cls, movement) -> "MovementOut":
        return cls(
            id=movement.id,
            item_id=movement.item_id,
            delta=movement.delta,
            quantity_after=movement.quantity_after,
            reason=movement.reason,
            created_at=movement.created_at,
            item_sku=movement.item.sku,
            item_name=movement.item.name,
        )


class InventoryStats(BaseModel):
    total_items: int
    total_units: int
    total_value: float
    low_stock: int
    out_of_stock: int
    categories: int
