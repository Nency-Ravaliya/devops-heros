# Build context: application/backend
#   docker build -f docker/backend.Dockerfile -t taskboard-backend:local application/backend

# ---- build stage: install dependencies into a virtualenv ----
FROM python:3.13-slim AS build
RUN python -m venv /venv
COPY requirements.txt .
RUN /venv/bin/pip install --no-cache-dir -r requirements.txt \
 && /venv/bin/pip uninstall -y pip

# ---- runtime stage: no pip, non-root user ----
FROM python:3.13-slim
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/venv/bin:$PATH"
RUN pip uninstall -y pip setuptools wheel 2>/dev/null; \
    useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin appuser

COPY --from=build /venv /venv
WORKDIR /app
COPY alembic.ini ./
COPY alembic ./alembic
COPY app ./app

ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}

USER 10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"
# migrations first, then the API
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --no-access-log"]
