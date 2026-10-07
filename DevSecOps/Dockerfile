FROM python:3.12-slim

# run as an unprivileged user (container hardening)
RUN useradd --create-home --uid 10001 appuser
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

ENV HOST=0.0.0.0 PORT=5001
EXPOSE 5001
USER 10001

CMD ["python", "app/app.py"]
