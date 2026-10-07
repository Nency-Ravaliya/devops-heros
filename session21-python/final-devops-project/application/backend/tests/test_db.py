from app.db import get_db


def test_get_db_yields_and_closes_session():
    gen = get_db()
    session = next(gen)
    assert session.is_active
    gen.close()  # runs the `finally: db.close()` branch
