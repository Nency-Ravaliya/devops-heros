FROM python:3.12-alpine
WORKDIR /app
COPY app.py ./app.py
RUN adduser -D -u 10001 appuser
USER appuser
EXPOSE 8080
CMD ["python", "app.py"]
