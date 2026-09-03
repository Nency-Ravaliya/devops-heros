FROM python:3.11-slim

WORKDIR /app

# python:3.11-slim already ships python3 + pip, so no apt-get is needed here.
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
