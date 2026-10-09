from flask import Flask
import mysql.connector
import time

app = Flask(__name__)


def get_db_connection():

    return mysql.connector.connect(
        host="database",
        user="root",
        password="root",
        database="demo"
    )


@app.route("/")
def hello():
    return "Hello from Backend!"


@app.route("/api")
def api():

    try:
        db = get_db_connection()
        cursor = db.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id INT AUTO_INCREMENT PRIMARY KEY,
                message VARCHAR(255)
            )
        """)

        cursor.execute(
            "INSERT INTO messages (message) VALUES ('Hello from MySQL!')"
        )

        db.commit()

        cursor.execute("SELECT message FROM messages ORDER BY id DESC LIMIT 1")

        result = cursor.fetchone()

        cursor.close()
        db.close()

        return {
            "backend": "Backend is working!",
            "database": result[0]
        }

    except Exception as e:
        return {
            "error": str(e)
        }, 500


app.run(host="0.0.0.0", port=5000)