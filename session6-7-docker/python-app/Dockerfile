FROM python:3.11-slim

WORKDIR /app

RUN apt update && apt install -y pip3 python3

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY app.py .

CMD ["python", "app.py"]