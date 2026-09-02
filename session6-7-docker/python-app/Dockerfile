FROM python:3.11-slim

WORKDIR /app

# Copy requirements first so the pip layer is cached when only source changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
