import pytest

from app.converter import UnknownUnit, convert


def test_km_to_m():
    assert convert("length", 1.5, "km", "m") == pytest.approx(1500)


def test_feet_to_inches():
    assert convert("length", 1, "ft", "in") == pytest.approx(12)


def test_kg_to_lb():
    assert convert("weight", 1, "kg", "lb") == pytest.approx(2.20462, rel=1e-4)


def test_celsius_to_fahrenheit():
    assert convert("temperature", 100, "c", "f") == pytest.approx(212)


def test_kelvin_round_trip():
    assert convert("temperature", convert("temperature", 25, "c", "k"), "k", "c") == pytest.approx(25)


def test_unknown_unit_raises():
    with pytest.raises(UnknownUnit):
        convert("length", 1, "m", "parsec")
