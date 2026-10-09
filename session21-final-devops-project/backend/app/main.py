from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from prometheus_fastapi_instrumentator import Instrumentator

from .config import settings
from .db import Base, engine, get_db
from .models import Lab
from .schemas import LabCreate, LabOut, LabUpdate, StatsOut

@asynccontextmanager
async def lifespan(_: FastAPI):
    # Alembic handles production migrations; this keeps local runs and tests simple.
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title=settings.app_name, version="1.0.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
Instrumentator().instrument(app).expose(app, endpoint="/metrics")

@app.get("/")
def root():
    return {"service": settings.app_name, "version": "1.0.0", "docs": "/docs"}

@app.get("/health")
def health():
    return {"status": "UP"}

@app.get("/ready")
def ready(db: Session = Depends(get_db)):
    db.execute(select(func.count(Lab.id)))
    return {"status": "READY"}

@app.get("/api/labs", response_model=list[LabOut])
def list_labs(db: Session = Depends(get_db)):
    return list(db.scalars(select(Lab).order_by(Lab.id.desc())))

@app.get("/api/labs/stats", response_model=StatsOut)
def stats(db: Session = Depends(get_db)):
    rows = db.execute(select(Lab.status, func.count(Lab.id)).group_by(Lab.status)).all()
    counts = dict(rows)
    return StatsOut(
        total=sum(counts.values()),
        planned=counts.get("PLANNED", 0),
        running=counts.get("RUNNING", 0),
        completed=counts.get("COMPLETED", 0),
    )

@app.get("/api/labs/{lab_id}", response_model=LabOut)
def get_lab(lab_id: int, db: Session = Depends(get_db)):
    lab = db.get(Lab, lab_id)
    if not lab:
        raise HTTPException(status_code=404, detail="Lab not found")
    return lab

@app.post("/api/labs", response_model=LabOut, status_code=status.HTTP_201_CREATED)
def create_lab(payload: LabCreate, db: Session = Depends(get_db)):
    lab = Lab(**payload.model_dump())
    db.add(lab)
    db.commit()
    db.refresh(lab)
    return lab

@app.put("/api/labs/{lab_id}", response_model=LabOut)
def update_lab(lab_id: int, payload: LabUpdate, db: Session = Depends(get_db)):
    lab = db.get(Lab, lab_id)
    if not lab:
        raise HTTPException(status_code=404, detail="Lab not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(lab, key, value)
    db.commit()
    db.refresh(lab)
    return lab

@app.delete("/api/labs/{lab_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_lab(lab_id: int, db: Session = Depends(get_db)):
    lab = db.get(Lab, lab_id)
    if not lab:
        raise HTTPException(status_code=404, detail="Lab not found")
    db.delete(lab)
    db.commit()
