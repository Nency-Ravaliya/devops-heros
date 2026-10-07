# syntax=docker/dockerfile:1

# ---------- Stage 1: build wheels ----------
FROM python:3.12-alpine AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt


# ---------- Stage 2: runtime ----------
FROM python:3.12-alpine

ARG GIT_SHA=dev
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    GIT_SHA=${GIT_SHA}

LABEL org.opencontainers.image.source="https://github.com/jenyyy4/devops-heros" \
      org.opencontainers.image.description="Session 17 DevSecOps demo (Flask)" \
      org.opencontainers.image.revision="${GIT_SHA}"

# Patch OS packages, then drop pip/setuptools tooling the app never needs at runtime
RUN apk upgrade --no-cache \
 && addgroup -S -g 10001 app \
 && adduser -S -D -H -u 10001 -G app app

WORKDIR /app
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir --no-index /wheels/* \
 && rm -rf /wheels \
 && pip uninstall -y pip setuptools wheel 2>/dev/null || true

COPY --chown=app:app app ./app

# Non-root user (Trivy DS-0002 / K8s runAsNonRoot)
USER 10001:10001

EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:5001/health', timeout=2).status == 200 else 1)"

# Production server instead of Flask's dev server; /tmp is an emptyDir in K8s (read-only root FS)
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "2", "--worker-tmp-dir", "/tmp", "--no-control-socket", "--access-logfile", "-", "app.app:app"]
