# ---- Build stage: install dependencies into an isolated prefix ----
FROM python:3.12-slim AS builder
ENV PIP_ROOT_USER_ACTION=ignore PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Runtime stage: small image, non-root user ----
FROM python:3.12-slim
ARG APP_VERSION=dev
ARG GIT_SHA=local
ENV APP_VERSION=${APP_VERSION} \
    GIT_SHA=${GIT_SHA} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000
LABEL org.opencontainers.image.title="session16-calculator-api" \
      org.opencontainers.image.source="https://github.com/jenyyy4/devops-heros"

WORKDIR /app
COPY --from=builder /install /usr/local
COPY app/ ./app/
RUN useradd --create-home --uid 1001 appuser
USER appuser

EXPOSE 5000
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app.main:app"]
