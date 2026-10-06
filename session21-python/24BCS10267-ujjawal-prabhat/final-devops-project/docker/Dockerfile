# syntax=docker/dockerfile:1.7
# StockPilot API - multi-stage build.
# Build context = ../application   (docker build -f docker/Dockerfile application)

ARG PYTHON_IMAGE=python:3.12-slim

# ---------- stage 1: build a self-contained virtualenv --------------------
FROM ${PYTHON_IMAGE} AS builder
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /build
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt \
 # the runtime never installs packages: strip pip/setuptools from the venv
 && pip uninstall -y pip setuptools || true

# ---------- stage 2: minimal runtime --------------------------------------
FROM ${PYTHON_IMAGE} AS runtime
ARG APP_VERSION=dev
LABEL org.opencontainers.image.title="stockpilot-api" \
      org.opencontainers.image.description="StockPilot inventory API (24BCS10267 final DevOps project)" \
      org.opencontainers.image.source="https://github.com/UjjawalPrabhat/devops-heros" \
      org.opencontainers.image.version="${APP_VERSION}"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    APP_VERSION=${APP_VERSION} \
    SQLITE_PATH=/data/stockpilot.db

# Patch OS packages, drop pip/setuptools from the system interpreter (not
# needed at runtime - they vendor urllib3/msgpack which Trivy flags) and create
# an unprivileged user with a fixed UID so Kubernetes runAsNonRoot can verify it.
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/local/lib/python3.12/site-packages/pip* \
           /usr/local/lib/python3.12/site-packages/setuptools* \
           /usr/local/bin/pip* \
 && groupadd --gid 10001 app \
 && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app \
 && mkdir -p /data && chown 10001:10001 /data

WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY --chown=10001:10001 app ./app

USER 10001:10001
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health',timeout=2).status==200 else 1)"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]
