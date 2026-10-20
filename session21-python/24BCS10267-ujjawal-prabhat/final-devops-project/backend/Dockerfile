# syntax=docker/dockerfile:1.7
# StockPilot backend (FastAPI). Build: docker build -t stockpilot-backend ./backend
ARG PYTHON_IMAGE=python:3.12-slim

# ---------- stage 1: build a self-contained virtualenv --------------------
FROM ${PYTHON_IMAGE} AS builder
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install -r requirements.txt
# the runtime never installs packages: strip pip/setuptools from the venv
RUN pip uninstall -y pip setuptools || true

# ---------- stage 2: minimal runtime --------------------------------------
FROM ${PYTHON_IMAGE} AS runtime
ARG APP_VERSION=dev
LABEL org.opencontainers.image.title="stockpilot-backend" \
      org.opencontainers.image.source="https://github.com/UjjawalPrabhat/devops-heros" \
      org.opencontainers.image.version="${APP_VERSION}"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    APP_VERSION=${APP_VERSION}

# Patch OS packages, drop pip/setuptools from the system interpreter (they vendor
# urllib3/msgpack, which Trivy flags) and create a fixed-UID non-root user so
# Kubernetes runAsNonRoot can verify it.
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/local/lib/python3.12/site-packages/pip* \
           /usr/local/lib/python3.12/site-packages/setuptools* \
           /usr/local/bin/pip* \
 && groupadd --gid 10001 app \
 && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app

WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY alembic.ini ./
COPY alembic ./alembic
COPY app ./app

USER 10001:10001
EXPOSE 8000

# Migrations run separately (`python -m app.migrate`: compose `migrate` service,
# Kubernetes init container), so several replicas never race at start-up.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]
