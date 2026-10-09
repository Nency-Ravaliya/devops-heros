from datetime import datetime, timezone

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


class Lab(Base):
    __tablename__ = "labs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    objective: Mapped[str] = mapped_column(Text, default="")
    tool: Mapped[str] = mapped_column(String(60), default="Kubernetes")
    difficulty: Mapped[str] = mapped_column(String(20), default="BEGINNER")
    status: Mapped[str] = mapped_column(String(30), default="PLANNED")
    owner: Mapped[str] = mapped_column(String(120), default="Anshal Kumar")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
