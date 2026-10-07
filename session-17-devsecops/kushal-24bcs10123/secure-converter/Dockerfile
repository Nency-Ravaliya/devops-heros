# ---- stage 1: dependencies into a virtualenv --------------------------------
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
# the runtime never installs anything, so pip itself leaves the venv once the dependencies are in
RUN python -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
 && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt \
 && /opt/venv/bin/pip uninstall -y pip setuptools

# ---- stage 2: hardened runtime ----------------------------------------------
FROM python:3.12-slim
ARG GIT_SHA=dev
ARG BUILD_NUMBER=local
ENV PATH=/opt/venv/bin:$PATH PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    GIT_SHA=$GIT_SHA BUILD_NUMBER=$BUILD_NUMBER
# pull in Debian security fixes, and remove the base image's pip: pip vendors setuptools, urllib3 and
# msgpack, and the scanner flags those. Nothing is ever installed at runtime, so pip has no job here.
RUN apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/local/lib/python3.12/site-packages/pip* /usr/local/lib/python3.12/ensurepip /usr/local/bin/pip* \
 && groupadd --system app && useradd --system --gid app --uid 10001 --home /app --shell /usr/sbin/nologin app
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY --chown=app:app app ./app
USER 10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health').status==200 else 1)"
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
