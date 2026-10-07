"""HTTP layer. Same converter as session 16 plus a bounded in-memory history."""

import collections
import os
import platform
import time

from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field

from . import __version__
from .converter import UnknownUnit, convert, units

app = FastAPI(title="secure-converter", version=__version__)
STARTED = time.time()
HISTORY: collections.deque = collections.deque(maxlen=int(os.getenv("HISTORY_SIZE", "20")))


class ConvertRequest(BaseModel):
    category: str = Field(pattern="^(length|weight|temperature)$")
    value: float
    from_unit: str = Field(min_length=1, max_length=4)
    to_unit: str = Field(min_length=1, max_length=4)


@app.get("/health")
def health():
    return {"status": "ok", "version": __version__, "uptime_seconds": round(time.time() - STARTED, 1)}


@app.get("/ready")
def ready():
    return {"ready": True}


@app.get("/info")
def info():
    return {
        "app": "secure-converter",
        "version": __version__,
        "python": platform.python_version(),
        "git_sha": os.getenv("GIT_SHA", "dev"),
        "build_number": os.getenv("BUILD_NUMBER", "local"),
    }


@app.get("/units")
def list_units():
    return units()


@app.post("/convert")
def convert_post(body: ConvertRequest):
    try:
        result = convert(body.category, body.value, body.from_unit, body.to_unit)
    except UnknownUnit as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    entry = {**body.model_dump(), "result": round(result, 6)}
    HISTORY.appendleft(entry)
    return entry


@app.get("/history")
def history(limit: int = Query(default=10, ge=1, le=20)):
    return list(HISTORY)[:limit]


@app.delete("/history")
def clear_history():
    HISTORY.clear()
    return {"cleared": True}
