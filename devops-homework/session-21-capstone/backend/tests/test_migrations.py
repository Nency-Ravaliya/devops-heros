import os
import subprocess

from sqlalchemy import create_engine, inspect


def test_migration_upgrade_and_downgrade(tmp_path):
    url = f"sqlite+pysqlite:///{tmp_path / 'migrations.db'}"
    env = {**os.environ, "DATABASE_URL": url}
    subprocess.run(["alembic", "upgrade", "head"], env=env, check=True)
    engine = create_engine(url)
    assert "tickets" in inspect(engine).get_table_names()
    assert {"ticket_priority", "ticket_status"} == {
        c["name"] for c in inspect(engine).get_check_constraints("tickets")
    }
    engine.dispose()
    subprocess.run(["alembic", "downgrade", "base"], env=env, check=True)
    engine = create_engine(url)
    assert "tickets" not in inspect(engine).get_table_names()
    engine.dispose()
