# ---- build stage: install dependencies into an isolated virtualenv ----
FROM python:3.12-slim AS builder
RUN python -m venv /opt/venv
COPY requirements.txt .
RUN /opt/venv/bin/pip install --no-cache-dir -r requirements.txt \
    && /opt/venv/bin/pip uninstall -y pip setuptools

# ---- runtime stage: no pip/setuptools (their vendored libs had HIGH CVEs) ----
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

RUN pip uninstall -y pip setuptools wheel || true \
    && rm -rf /usr/local/lib/python3.12/ensurepip \
    && useradd --create-home --uid 10001 appuser

WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY app ./app

USER 10001
EXPOSE 5001
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "2", "app.app:app"]
