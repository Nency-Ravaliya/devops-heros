# Dockerfiles & Images — Homework Submission

- **Name:** Krushna Sonawane
- **Enrollment Number:** DEV-2026-10464
- **Course:** DevOps Engineering & Containerization
- **Task:** Docker Multi-Stage Build — run the image and serve on port **8080**

## Application running successfully

`http://127.0.0.1:8080/` returns:

> **Hello World from Docker multi-stage build**

## Running containers (evidence)

```
$ docker ps
NAMES           IMAGE            PORTS                     STATUS
hw-multistage   hw-multistage    0.0.0.0:8080->8080/tcp    Up 3 seconds
```

## Task 3 — 3 application types deployed

Node.js, Python, and Java each built as an image and run as a container.

```
NAMES       IMAGE        PORTS                     STATUS
hw-nodejs   hw-nodejs    0.0.0.0:3001->3000/tcp    Up 3 minutes
hw-python   hw-python    0.0.0.0:5001->5000/tcp    Up 3 minutes
hw-java     hw-java      0.0.0.0:8081->8080/tcp    Up 3 minutes
```

## Verification

```
nodejs (:3001)        Hello World from Node.js
python (:5001)        Hello World from Python
java   (:8081)        Hello World from Java
```
