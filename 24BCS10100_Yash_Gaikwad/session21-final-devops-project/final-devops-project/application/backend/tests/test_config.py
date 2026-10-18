import pytest

from app.config import get_database_url


def test_database_url_comes_from_the_environment(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "sqlite://")
    assert get_database_url() == "sqlite://"


def test_missing_database_url_is_a_clear_error(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    with pytest.raises(RuntimeError, match="DATABASE_URL is not set"):
        get_database_url()
