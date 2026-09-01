FROM python:3.11-slim

WORKDIR /app

# Copy dependency definition first to leverage Docker layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY app.py .

EXPOSE 5001

CMD ["python", "app.py"]
