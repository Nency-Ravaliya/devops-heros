# CI/CD Pipeline Concepts

```text
Code Push --> Build --> Test --> Package --> Deploy
```

Every step depends on the previous one passing.

---

## 1. What is a Pipeline?

A pipeline is a sequence of automated stages that code passes through after a commit.

```text
Stage 1: Source
         Pull code from Git

Stage 2: Build
         Compile or package the application

Stage 3: Test
         Run unit tests, integration tests, lint

Stage 4: Artifact
         Create Docker image, zip file, JAR

Stage 5: Deploy
         Push to staging or production
```

---

## 2. Why Stages?

Each stage acts as a gate.

```text
If Build fails  --> Pipeline stops, nobody deploys broken code
If Tests fail   --> Pipeline stops, nobody deploys untested code
If Lint fails   --> Pipeline stops, nobody deploys unmaintainable code
```

---

## 3. Pipeline Vocabulary

```text
Pipeline   = the entire automated workflow
Stage      = a logical group of related work (build, test, deploy)
Job        = a unit of work that runs on one machine
Step       = a single command or action inside a job
Runner     = the machine that executes jobs
Artifact   = the output produced by a job (binary, image, report)
Trigger    = the event that starts the pipeline (push, PR, schedule)
```

---

## 4. Linear vs Parallel

**Linear pipeline:**

```text
Build --> Test --> Deploy
```

Each stage waits for the previous one.

**Parallel pipeline:**

```text
          ┌─── Unit Tests ───┐
Build ────┤                  ├─── Deploy
          └─── Lint ─────────┘
```

Unit Tests and Lint run at the same time. Both must pass before Deploy.

---

## 5. Pipeline Failure Modes

```text
[FAIL] Build fails    = code does not compile
[FAIL] Test fails     = a test assertion is wrong
[FAIL] Lint fails     = code style violation
[FAIL] Deploy fails   = environment problem, config missing
[FAIL] Timeout        = job took too long
```

---

## 6. Artifacts in a Pipeline

```text
Build job produces:   app binary / Docker image
Test job produces:    test report, coverage report
Deploy job consumes:  the Docker image from Build
```

Artifacts let jobs share data without re-running earlier steps.

---

## Key Learning

```text
Pipeline = sequence of automated stages
Stage    = logical group (build, test, deploy)
Job      = work on one machine
Step     = one command
Artifact = output passed between jobs
Trigger  = event that starts the pipeline
```

---

## Reference

* **GitHub Actions workflow basics:** https://docs.github.com/en/actions/using-workflows
