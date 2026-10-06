from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ItemCreate(BaseModel):
    sku: str = Field(min_length=2, max_length=32, pattern=r"^[A-Z0-9-]+$")
    name: str = Field(min_length=1, max_length=120)
    location: str = Field(default="MAIN", max_length=60)
    quantity: int = Field(default=0, ge=0)
    reorder_level: Optional[int] = Field(default=None, ge=0)
    unit_price_paise: int = Field(default=0, ge=0)


class ItemUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    location: Optional[str] = Field(default=None, max_length=60)
    quantity: Optional[int] = Field(default=None, ge=0)
    reorder_level: Optional[int] = Field(default=None, ge=0)
    unit_price_paise: Optional[int] = Field(default=None, ge=0)


class StockAdjustment(BaseModel):
    delta: int = Field(description="Positive to receive stock, negative to issue stock")
    reason: str = Field(default="manual", max_length=60)


class ItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sku: str
    name: str
    location: str
    quantity: int
    reorder_level: int
    unit_price_paise: int
    low_stock: bool
    updated_at: datetime


class Summary(BaseModel):
    total_items: int
    total_units: int
    low_stock_items: int
    inventory_value_paise: int
