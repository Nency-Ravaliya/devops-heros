from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

TicketStatus = Literal["open", "in_progress", "resolved"]
Priority = Literal["low", "medium", "high", "urgent"]


class TicketWrite(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")
    title: str = Field(min_length=3, max_length=160)
    description: str = Field(default="", max_length=5000)
    requester: str = Field(min_length=3, max_length=160)
    assignee: str = Field(default="", max_length=80)
    priority: Priority = "medium"
    status: TicketStatus = "open"

    @field_validator("requester")
    @classmethod
    def requester_email(cls, value):
        if "@" not in value or "." not in value.rsplit("@", 1)[-1] or " " in value:
            raise ValueError("Provide a requester email address")
        return value


class TicketRead(TicketWrite):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime
    updated_at: datetime


class TicketList(BaseModel):
    items: list[TicketRead]
    total: int
    limit: int
    offset: int


class TicketStats(BaseModel):
    total: int
    open: int
    in_progress: int
    resolved: int
    urgent: int
