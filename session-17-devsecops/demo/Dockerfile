# DevSecOps Hardened Multi-Stage / Minimal Python Container
FROM python:3.12-slim

# Set environment variables for security and logging
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install security updates and curl for container health check
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY app/ ./app/

# Implement Principle of Least Privilege: Non-Root Execution
RUN useradd -u 10001 -m appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 5001

# Healthcheck instruction for container runtime
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5001/health || exit 1

CMD ["python", "app/app.py"]