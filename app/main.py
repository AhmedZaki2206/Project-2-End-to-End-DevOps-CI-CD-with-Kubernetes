from __future__ import annotations

import json
import logging
import os
import sys
import time
import uuid
from datetime import datetime, timezone

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class JsonFormatter(logging.Formatter):
    """Render application logs as one JSON object per stdout line."""

    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        for field in ("request_id", "method", "path", "status_code", "duration_ms"):
            if hasattr(record, field):
                payload[field] = getattr(record, field)
        return json.dumps(payload, separators=(",", ":"))


handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
logger = logging.getLogger("cloud-native-api")
logger.handlers = [handler]
logger.setLevel(os.getenv("LOG_LEVEL", "INFO").upper())
logger.propagate = False

APP_NAME = "cloud-native-cicd-kubernetes"
APP_VERSION = os.getenv("APP_VERSION", "dev")
READY = os.getenv("APP_READY", "true").lower() == "true"

app = FastAPI(title=APP_NAME, version=APP_VERSION)


@app.middleware("http")
async def request_logging(request: Request, call_next):
    request_id = request.headers.get("x-request-id", str(uuid.uuid4()))
    started = time.perf_counter()
    response = await call_next(request)
    duration_ms = round((time.perf_counter() - started) * 1000, 2)
    response.headers["x-request-id"] = request_id
    logger.info(
        "request_completed",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "duration_ms": duration_ms,
        },
    )
    return response


@app.get("/")
def root() -> dict[str, str]:
    return {"service": APP_NAME, "message": "Cloud-native delivery pipeline is running"}


@app.get("/health/live")
def liveness() -> dict[str, str]:
    return {"status": "alive"}


@app.get("/health/ready")
def readiness():
    if not READY:
        return JSONResponse(status_code=503, content={"status": "not-ready"})
    return {"status": "ready"}


@app.get("/version")
def version() -> dict[str, str]:
    return {"version": APP_VERSION}

