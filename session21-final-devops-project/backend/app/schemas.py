from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

LabStatus = Literal["PLANNED", "RUNNING", "COMPLETED"]
Difficulty = Literal["BEGINNER", "INTERMEDIATE", "ADVANCED"]
Tool = Literal["Docker", "Kubernetes", "Terraform", "CI/CD", "Monitoring"]


class LabCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    objective: str = ""
    tool: Tool = "Kubernetes"
    difficulty: Difficulty = "BEGINNER"
    status: LabStatus = "PLANNED"
    owner: str = "Anshal Kumar"


class LabUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    objective: str | None = None
    tool: Tool | None = None
    difficulty: Difficulty | None = None
    status: LabStatus | None = None
    owner: str | None = None


class LabOut(LabCreate):
    id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)


class StatsOut(BaseModel):
    total: int
    planned: int
    running: int
    completed: int
