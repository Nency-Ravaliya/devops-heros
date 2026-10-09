# Stage 1: Build & Dependency Wheel Cache
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Minimal Distroless / Production Runtime
FROM python:3.12-alpine AS runtime

LABEL maintainer="Durga Prasad <bdurga.24bcs10012@sst.scaler.com>"
LABEL session="Session 16 - CI/CD & GitHub Actions"

WORKDIR /app

# Create non-root system user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy dependencies and application
COPY --from=builder /root/.local /home/appuser/.local
COPY app/ /app/app/

USER appuser
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["python", "/app/app/calculator.py"]
CMD ["add", "10", "20"]
