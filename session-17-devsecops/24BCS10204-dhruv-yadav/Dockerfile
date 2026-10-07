# ---- build stage: install deps into an isolated virtualenv ----
FROM python:3.12-alpine AS builder
WORKDIR /build
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
 # the runtime never installs packages: drop pip/setuptools (and their vendored libs) from the venv
 && pip uninstall -y pip setuptools

# ---- runtime stage: minimal base, no package manager tooling, non-root user ----
FROM python:3.12-alpine
RUN apk upgrade --no-cache \
 && rm -rf /usr/local/lib/python3.12/site-packages/pip* \
           /usr/local/lib/python3.12/site-packages/setuptools* \
           /usr/local/bin/pip* \
 && addgroup -g 10001 -S app && adduser -u 10001 -S -G app -H -s /sbin/nologin app
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY app ./app
USER 10001:10001
EXPOSE 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--worker-tmp-dir", "/tmp", "--no-control-socket", "--access-logfile", "-", "app.main:app"]
