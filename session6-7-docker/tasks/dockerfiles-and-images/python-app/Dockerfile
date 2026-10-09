# Stage 1: build the dependencies into a virtualenv. The full python image is
# used here because it carries the compilers some packages need to build.
FROM python:3.12 AS builder

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: runtime on the slim image, which has no compilers at all. The
# finished virtualenv is copied in whole - a self-contained directory, so
# copying it is enough to bring the dependencies across.
FROM python:3.12-slim AS production

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY app.py ./

EXPOSE 8080
CMD ["python", "app.py"]
