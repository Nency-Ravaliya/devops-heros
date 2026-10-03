import os

import pymysql
from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/api")
def database_check():
    connection = pymysql.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        connect_timeout=3,
    )
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT DATABASE()")
            database = cursor.fetchone()[0]
    finally:
        connection.close()

    return jsonify(service="backend", database=database, status="connected")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
