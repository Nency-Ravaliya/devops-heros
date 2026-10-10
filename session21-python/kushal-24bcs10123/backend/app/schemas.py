from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

Status = Literal["planned", "in_progress", "done"]


class StudyEntryBase(BaseModel):
    subject: str = Field(min_length=1, max_length=80, examples=["Operating Systems"])
    topic: str = Field(min_length=1, max_length=200, examples=["Paging and TLB"])
    minutes: int = Field(ge=1, le=600, default=30)
    status: Status = "planned"
    notes: str = Field(default="", max_length=2000)


class StudyEntryCreate(StudyEntryBase):
    pass


class StudyEntryUpdate(BaseModel):
    subject: str | None = Field(default=None, min_length=1, max_length=80)
    topic: str | None = Field(default=None, min_length=1, max_length=200)
    minutes: int | None = Field(default=None, ge=1, le=600)
    status: Status | None = None
    notes: str | None = Field(default=None, max_length=2000)


class StudyEntryOut(StudyEntryBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
    updated_at: datetime


class SubjectTotal(BaseModel):
    subject: str
    minutes: int
    entries: int


class Summary(BaseModel):
    total_entries: int
    total_minutes: int
    done_minutes: int
    daily_goal_minutes: int
    goal_reached: bool
    by_status: dict[str, int]
    by_subject: list[SubjectTotal]
