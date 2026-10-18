FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# dependencies first so this layer is cached until requirements.txt changes
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY alembic.ini .
COPY alembic ./alembic
COPY app ./app

# which commit this image was built from (CI passes the real SHA)
ARG COMMIT_SHA=local
LABEL org.opencontainers.image.title="stockpilot-backend" \
      org.opencontainers.image.revision=$COMMIT_SHA

# numeric uid so Kubernetes can verify runAsNonRoot
RUN useradd --create-home --uid 10001 appuser && chown -R appuser /app
USER 10001

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)"

# run migrations, then hand the process over to uvicorn
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port 8000"]
