"""Runtime configuration, read from environment variables.

In Kubernetes the non-secret values come from a ConfigMap and the database
password comes from a Secret (see helm/stockpilot/templates).
"""
import os
from dataclasses import dataclass, field


def _database_url() -> str:
    # Explicit URL wins (used by tests and local dev).
    url = os.getenv("DATABASE_URL")
    if url:
        return url
    host = os.getenv("DB_HOST")
    if host:
        user = os.getenv("DB_USER", "stockpilot")
        password = os.getenv("DB_PASSWORD", "")
        name = os.getenv("DB_NAME", "stockpilot")
        port = os.getenv("DB_PORT", "5432")
        return f"postgresql+psycopg://{user}:{password}@{host}:{port}/{name}"
    # Fallback for docker run / local dev without PostgreSQL.
    return f"sqlite:///{os.getenv('SQLITE_PATH', './stockpilot.db')}"


@dataclass(frozen=True)
class Settings:
    app_name: str = field(default_factory=lambda: os.getenv("APP_NAME", "StockPilot"))
    app_env: str = field(default_factory=lambda: os.getenv("APP_ENV", "local"))
    app_version: str = field(default_factory=lambda: os.getenv("APP_VERSION", "1.0.0"))
    log_level: str = field(default_factory=lambda: os.getenv("LOG_LEVEL", "info"))
    default_reorder_level: int = field(
        default_factory=lambda: int(os.getenv("DEFAULT_REORDER_LEVEL", "10"))
    )
    database_url: str = field(default_factory=_database_url)


settings = Settings()
