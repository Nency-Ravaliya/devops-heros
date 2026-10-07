FROM python:3.12-slim

WORKDIR /app
COPY app/ ./app/

# Non-interactive smoke run (calculator.py's main loop needs a terminal)
CMD ["python", "-c", "from app.calculator import add, subtract, multiply, divide; print('Session 16 Calculator'); print('10 + 5 =', add(10, 5)); print('10 - 5 =', subtract(10, 5)); print('10 * 5 =', multiply(10, 5)); print('10 / 5 =', divide(10, 5))"]
