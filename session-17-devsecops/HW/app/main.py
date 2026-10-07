"""Tiny task-tracker API used to demo a DevSecOps pipeline."""
import os
import threading

from flask import Flask, jsonify, request

app = Flask(__name__)

APP_VERSION = os.environ.get("APP_VERSION", "dev")
MAX_TITLE_LEN = 100

_tasks = {}
_next_id = 1
_lock = threading.Lock()


@app.after_request
def security_headers(resp):
    resp.headers["X-Content-Type-Options"] = "nosniff"
    resp.headers["X-Frame-Options"] = "DENY"
    resp.headers["Content-Security-Policy"] = "default-src 'none'"
    return resp


@app.get("/")
def index():
    return jsonify(app="session17-tasks", version=APP_VERSION)


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/api/tasks")
def list_tasks():
    return jsonify(tasks=list(_tasks.values()))


@app.post("/api/tasks")
def create_task():
    global _next_id
    data = request.get_json(silent=True) or {}
    title = data.get("title")
    if not isinstance(title, str) or not title.strip():
        return jsonify(error="'title' is required"), 400
    title = title.strip()
    if len(title) > MAX_TITLE_LEN:
        return jsonify(error=f"'title' must be at most {MAX_TITLE_LEN} characters"), 400
    with _lock:
        task = {"id": _next_id, "title": title, "done": False}
        _tasks[_next_id] = task
        _next_id += 1
    return jsonify(task), 201


@app.get("/api/tasks/<int:task_id>")
def get_task(task_id):
    task = _tasks.get(task_id)
    if task is None:
        return jsonify(error="task not found"), 404
    return jsonify(task)


@app.post("/api/tasks/<int:task_id>/done")
def complete_task(task_id):
    task = _tasks.get(task_id)
    if task is None:
        return jsonify(error="task not found"), 404
    task["done"] = True
    return jsonify(task)


@app.delete("/api/tasks/<int:task_id>")
def delete_task(task_id):
    with _lock:
        task = _tasks.pop(task_id, None)
    if task is None:
        return jsonify(error="task not found"), 404
    return "", 204


def reset():
    """Clear the in-memory store (used by tests)."""
    global _next_id
    with _lock:
        _tasks.clear()
        _next_id = 1


if __name__ == "__main__":
    # local dev only; the container runs gunicorn
    app.run(host="127.0.0.1", port=int(os.environ.get("PORT", "8080")))
