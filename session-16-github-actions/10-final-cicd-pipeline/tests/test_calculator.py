import sys
import os
import pytest

# Ensure app package is importable
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.calculator import add, subtract, multiply, divide, power, modulo


def test_add_positive():
    assert add(10, 5) == 15
    assert add(2.5, 3.5) == 6.0


def test_add_negative():
    assert add(-4, -6) == -10
    assert add(-5, 5) == 0


def test_subtract():
    assert subtract(10, 4) == 6
    assert subtract(5, 10) == -5


def test_multiply():
    assert multiply(3, 4) == 12
    assert multiply(-2, 3) == -6
    assert multiply(10, 0) == 0


def test_divide():
    assert divide(10, 2) == 5.0
    assert divide(7, 2) == 3.5


def test_divide_by_zero():
    with pytest.raises(ValueError) as excinfo:
        divide(10, 0)
    assert "Cannot divide by zero" in str(excinfo.value)


def test_power():
    assert power(2, 3) == 8
    assert power(5, 0) == 1


def test_modulo():
    assert modulo(10, 3) == 1
    with pytest.raises(ValueError):
        modulo(10, 0)
