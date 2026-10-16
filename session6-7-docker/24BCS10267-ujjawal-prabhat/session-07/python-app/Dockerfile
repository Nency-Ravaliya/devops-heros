# Multi-stage build
# Stage 1: install dependencies into a virtualenv using the full Python image
FROM python:3.12 AS build
RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: copy only the virtualenv + app onto the slim image
FROM python:3.12-slim
ENV PATH="/venv/bin:$PATH" PYTHONUNBUFFERED=1
COPY --from=build /venv /venv
WORKDIR /app
COPY app.py .
RUN useradd --no-create-home appuser
USER appuser
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
