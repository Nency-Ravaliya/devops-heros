FROM python:3.12-slim

# Don't run as root inside the container
RUN useradd --create-home appuser
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} PORT=8000
EXPOSE 8000
USER appuser

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app.main:app"]
