"""Run `alembic upgrade head`, waiting for the database first.

Used by the Kubernetes init container and the docker-compose `migrate` service:
    python -m app.migrate
A database that is still starting is retried instead of failing the pod.
"""
import logging
import os
import sys
import time
from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import text
from sqlalchemy.exc import OperationalError

from .db import engine

log = logging.getLogger("stockpilot.migrate")
ALEMBIC_INI = Path(__file__).resolve().parent.parent / "alembic.ini"


def wait_for_db(attempts: int, delay: float) -> None:
    for i in range(1, attempts + 1):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            return
        except OperationalError as exc:
            log.warning("database not reachable (attempt %d/%d): %s", i, attempts, str(exc).splitlines()[0])
            time.sleep(delay)
    sys.exit("database never became reachable")


def main() -> None:
    logging.basicConfig(level="INFO", format="%(asctime)s %(levelname)s %(name)s %(message)s")
    wait_for_db(int(os.getenv("MIGRATE_ATTEMPTS", "60")), float(os.getenv("MIGRATE_DELAY", "2")))
    cfg = Config(str(ALEMBIC_INI))
    cfg.set_main_option("script_location", str(ALEMBIC_INI.parent / "alembic"))
    command.upgrade(cfg, "head")
    print("database schema is at head", flush=True)


if __name__ == "__main__":
    main()
