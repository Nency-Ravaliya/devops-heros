"""HTTP layer of the unit-converter service."""

import os
import platform
import time

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from . import __version__
from .converter import UnknownUnit, convert, units

app = FastAPI(title="unit-converter", version=__version__)
STARTED = time.time()


class ConvertRequest(BaseModel):
    category: str
    value: float
    from_unit: str
    to_unit: str


@app.get("/health")
def health():
    return {"status": "ok", "version": __version__, "uptime_seconds": round(time.time() - STARTED, 1)}


@app.get("/info")
def info():
    return {
        "app": "unit-converter",
        "version": __version__,
        "python": platform.python_version(),
        "git_sha": os.getenv("GIT_SHA", "dev"),
        "build_number": os.getenv("BUILD_NUMBER", "local"),
    }


@app.get("/units")
def list_units():
    return units()


@app.get("/convert/{category}")
def convert_get(category: str, value: float, from_unit: str, to_unit: str):
    try:
        result = convert(category, value, from_unit, to_unit)
    except UnknownUnit as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {"category": category, "value": value, "from": from_unit, "to": to_unit, "result": round(result, 6)}


@app.post("/convert")
def convert_post(body: ConvertRequest):
    return convert_get(body.category, body.value, body.from_unit, body.to_unit)
