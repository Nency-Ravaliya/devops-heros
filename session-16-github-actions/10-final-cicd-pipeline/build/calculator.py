"""
Calculator Application - Session 16 CI/CD Demo
Provides basic and extended arithmetic operations with both interactive CLI
and automated execution modes for testing and containerized verification.
"""

import sys
import re


def add(a, b):
    """Return the sum of two numbers."""
    return a + b


def subtract(a, b):
    """Return the difference of two numbers."""
    return a - b


def multiply(a, b):
    """Return the product of two numbers."""
    return a * b


def divide(a, b):
    """Return the quotient of two numbers. Raises ValueError on division by zero."""
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b


def power(a, b):
    """Return a raised to the power of b."""
    return a ** b


def modulo(a, b):
    """Return the modulo remainder of a divided by b."""
    if b == 0:
        raise ValueError("Cannot perform modulo with zero divisor")
    return a % b


def run_demo():
    """Run automated demonstration of all arithmetic operations."""
    print("==========================================")
    print("  DevOps Heroes - Calculator CI/CD Demo   ")
    print("==========================================")
    print(f" [+] Addition:       10 + 5  = {add(10, 5)}")
    print(f" [+] Subtraction:    10 - 5  = {subtract(10, 5)}")
    print(f" [+] Multiplication: 10 * 5  = {multiply(10, 5)}")
    print(f" [+] Division:       10 / 5  = {divide(10, 5)}")
    print(f" [+] Power:          2 ** 3  = {power(2, 3)}")
    print(f" [+] Modulo:         10 % 3  = {modulo(10, 3)}")
    print("==========================================")
    print(" All operations executed successfully!")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] in ("--demo", "-d", "--test"):
            run_demo()
            sys.exit(0)
        elif len(sys.argv) == 4:
            try:
                op_a = float(sys.argv[1])
                operator = sys.argv[2]
                op_b = float(sys.argv[3])
                if operator == '+':
                    print(f"Result: {add(op_a, op_b)}")
                elif operator == '-':
                    print(f"Result: {subtract(op_a, op_b)}")
                elif operator in ('*', 'x'):
                    print(f"Result: {multiply(op_a, op_b)}")
                elif operator == '/':
                    print(f"Result: {divide(op_a, op_b)}")
                elif operator in ('^', '**'):
                    print(f"Result: {power(op_a, op_b)}")
                elif operator == '%':
                    print(f"Result: {modulo(op_a, op_b)}")
                else:
                    print(f"Error: Unknown operator '{operator}'")
                    sys.exit(1)
                sys.exit(0)
            except ValueError as e:
                print(f"Error: {e}")
                sys.exit(1)

    print("Calculator Application")
    print("----------------------")
    print("Available operations: +, -, *, /, **, %")
    print("Run with '--demo' for automated test mode.")
    print("Type 'q' or 'quit' to exit.")

    while True:
        try:
            expr = input("\nEnter calculation (e.g., 10 + 5): ")
            if expr.lower() in ('q', 'quit'):
                print("Goodbye!")
                break

            match = re.match(r"^\s*([\d\.]+)\s*([\+\-\*\/%^]|\*\*)\s*([\d\.]+)\s*$", expr)
            if not match:
                print("Invalid format. Please use: number operation number (e.g., 10 + 5 or 2 ** 3)")
                continue

            a, op, b = float(match.group(1)), match.group(2), float(match.group(3))

            if op == '+':
                print(f"Result: {add(a, b)}")
            elif op == '-':
                print(f"Result: {subtract(a, b)}")
            elif op == '*':
                print(f"Result: {multiply(a, b)}")
            elif op == '/':
                print(f"Result: {divide(a, b)}")
            elif op in ('^', '**'):
                print(f"Result: {power(a, b)}")
            elif op == '%':
                print(f"Result: {modulo(a, b)}")
            else:
                print(f"Unknown operation: {op}")
        except ValueError as e:
            print(f"Error: {e}")
        except Exception as e:
            print(f"Unexpected error: {e}")
