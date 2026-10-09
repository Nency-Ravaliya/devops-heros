FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
<<<<<<< HEAD:session6-docker/python-app/Dockerfile
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5001
CMD ["python", "app.py"]
=======

RUN pip install -r requirements.txt

COPY app.py .

CMD ["python", "app.py"]
>>>>>>> upstream/main:session6-7-docker/python-app/Dockerfile
