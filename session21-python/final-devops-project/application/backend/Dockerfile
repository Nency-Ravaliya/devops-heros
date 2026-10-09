# syntax=docker/dockerfile:1
# TaskBoard API — multi-stage build
#   stage 1 (builder): install Python deps into an isolated virtualenv
#   stage 2 (runtime): copy only the venv + app code, run as a non-root user

FROM python:3.12.15-alpine3.24 AS builder
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
 && pip uninstall -y pip   # pip is a build tool: not shipped in the runtime venv

FROM python:3.12.15-alpine3.24 AS runtime
ARG GIT_SHA=dev
LABEL org.opencontainers.image.title="taskboard-backend" \
      org.opencontainers.image.description="TaskBoard FastAPI backend" \
      org.opencontainers.image.revision="${GIT_SHA}"
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    GIT_SHA=${GIT_SHA}
# Base image choice: python:3.12-slim-trixie carried 44 HIGH OS CVEs with no fix available;
# the Alpine variant scans clean and is ~40% smaller. `apk upgrade` pulls fixes released
# after the base was published, and the base image's pip is removed (build-only tool, had CVEs).
RUN python -m pip uninstall -y pip \
 && apk upgrade --no-cache \
 && addgroup -g 10001 appuser \
 && adduser -u 10001 -G appuser -H -D -s /sbin/nologin appuser
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY --chown=10001:10001 alembic.ini ./
COPY --chown=10001:10001 alembic ./alembic
COPY --chown=10001:10001 app ./app
USER 10001:10001
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).status == 200 else 1)"]
# Apply DB migrations, then exec uvicorn as PID 1 so it receives SIGTERM directly.
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --proxy-headers"]
