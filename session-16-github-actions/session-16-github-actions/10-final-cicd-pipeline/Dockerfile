# Multi-stage Dockerfile for Calculator CI/CD Demo Application
FROM python:3.12-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Final production stage
FROM python:3.12-slim

WORKDIR /app

# Non-root security user
RUN useradd -u 1001 -m appuser

# Copy installed dependencies and application code
COPY --from=builder /root/.local /home/appuser/.local
COPY app/ ./app/
COPY build.sh .

ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

USER appuser

EXPOSE 8080

CMD ["python", "app/calculator.py"]
