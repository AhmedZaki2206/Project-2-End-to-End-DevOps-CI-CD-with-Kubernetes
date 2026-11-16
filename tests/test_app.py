import json
import logging

from fastapi.testclient import TestClient

import app.main as app_module
from app.main import JsonFormatter, app


client = TestClient(app)


def test_root() -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == "cloud-native-cicd-kubernetes"
    assert "x-request-id" in response.headers


def test_liveness() -> None:
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "alive"}


def test_readiness() -> None:
    response = client.get("/health/ready")
    assert response.status_code == 200
    assert response.json() == {"status": "ready"}


def test_readiness_returns_503_when_disabled(monkeypatch) -> None:
    monkeypatch.setattr(app_module, "READY", False)
    response = client.get("/health/ready")
    assert response.status_code == 503
    assert response.json() == {"status": "not-ready"}


def test_version() -> None:
    response = client.get("/version")
    assert response.status_code == 200
    assert response.json() == {"version": "dev"}


def test_json_formatter() -> None:
    record = logging.LogRecord("test", logging.INFO, "", 0, "hello", (), None)
    payload = json.loads(JsonFormatter().format(record))
    assert payload["level"] == "INFO"
    assert payload["message"] == "hello"
    assert payload["logger"] == "test"
    assert "timestamp" in payload

