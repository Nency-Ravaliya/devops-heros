# -------------------------
# Stage 1: Build
# -------------------------

FROM python:3.9-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

# -------------------------
# Stage 2: Production
# -------------------------

FROM python:3.9-slim
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY . .
ENV PATH="/opt/venv/bin:$PATH"
EXPOSE 5001
CMD [ "python", "app.py" ]