from flask import Flask, jsonify, request
import platform
import datetime
import sys
import os

app = Flask(__name__)

_request_count = 0
_start_time = datetime.datetime.utcnow()

def _increment_requests():
    global _request_count
    _request_count += 1

@app.route("/")
def home():
    _increment_requests()
    return jsonify({"message": "DevSecOps Demo Application", "status": "running"})

@app.route("/health")
def health():
    _increment_requests()
    uptime_seconds = (datetime.datetime.utcnow() - _start_time).total_seconds()
    return jsonify({
        "status": "healthy",
        "uptime_seconds": round(uptime_seconds, 2),
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    })

@app.route("/api/status")
def status():
    _increment_requests()
    return jsonify({
        "app": "DevSecOps Dashboard",
        "version": "2.0.0",
        "status": "running",
        "python_version": sys.version.split()[0],
        "platform": platform.system(),
        "total_requests": _request_count,
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
