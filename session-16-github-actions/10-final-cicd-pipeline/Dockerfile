FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY app/ ./app/

RUN useradd --create-home --uid 10001 calculator
USER calculator

CMD ["python", "-m", "app.calculator"]
