"""
Production Calculator Application for CI/CD Demo
Course: SST DevOps & Cloud
Session: 16 - CI/CD & GitHub Actions
Author: Durga Prasad (Enrollment: 10012)
"""

import sys


def add(a: float, b: float) -> float:
    """Add two numbers."""
    return a + b


def subtract(a: float, b: float) -> float:
    """Subtract b from a."""
    return a - b


def multiply(a: float, b: float) -> float:
    """Multiply two numbers."""
    return a * b


def divide(a: float, b: float) -> float:
    """Divide a by b with zero-division protection."""
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b


def power(a: float, b: float) -> float:
    """Raise a to the power of b."""
    return a ** b


def modulo(a: float, b: float) -> float:
    """Modulo operation with zero protection."""
    if b == 0:
        raise ValueError("Cannot compute modulo by zero")
    return a % b


def main():
    print("========================================")
    print(" DevOps Calculator CLI v1.0.0")
    print(" Author: Durga Prasad (10012)")
    print("========================================")
    if len(sys.argv) == 4:
        op = sys.argv[1]
        try:
            x = float(sys.argv[2])
            y = float(sys.argv[3])
            if op == "add":
                print(f"Result: {add(x, y)}")
            elif op == "sub":
                print(f"Result: {subtract(x, y)}")
            elif op == "mul":
                print(f"Result: {multiply(x, y)}")
            elif op == "div":
                print(f"Result: {divide(x, y)}")
            else:
                print(f"Unknown operation: {op}")
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)
    else:
        print("Usage: python3 calculator.py <add|sub|mul|div> <num1> <num2>")


if __name__ == "__main__":
    main()
