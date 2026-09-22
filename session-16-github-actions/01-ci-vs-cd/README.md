# CI vs CD

```text
Developer pushes code
        │
        ▼
  CI kicks in
        │
        ▼
Build and Test
        │
        ▼
  Tests pass?
        │
     Yes/No
        │
        ▼
  CD kicks in
        │
        ▼
Deploy to staging or production
```

---

## 1. What is CI?

CI stands for Continuous Integration.

Every time a developer pushes code, an automated system:

```text
1. Pulls the latest code
2. Builds the application
3. Runs all tests
4. Reports success or failure
```

The goal is to find integration problems early, before they reach production.

---

## 2. What Problem Does CI Solve?

Without CI:

```text
Developer A works for 2 weeks
Developer B works for 2 weeks
They merge
Everything breaks
Nobody knows why
```

With CI:

```text
Developer A pushes
Tests run immediately
Failure is caught the same day
Root cause is obvious
```

---

## 3. What is CD?

CD can mean two different things.

**Continuous Delivery:**

```text
Code passes CI
        │
        ▼
App is packaged
        │
        ▼
App is ready to deploy
        │
        ▼
Deployment requires human approval
```

**Continuous Deployment:**

```text
Code passes CI
        │
        ▼
App is packaged
        │
        ▼
App is automatically deployed to production
        (no human approval needed)
```

---

## 4. The Difference

```text
CI:                 Build + Test on every push
Continuous Delivery:   Auto-package, manual deploy
Continuous Deployment: Auto-package, auto-deploy
```

Most companies use Continuous Delivery. They want a human to approve production deployments.

---

## 5. The Full Pipeline

```text
Code Push
    │
    ▼
Source Control (Git)
    │
    ▼
CI: Build
    │
    ▼
CI: Unit Tests
    │
    ▼
CI: Integration Tests
    │
    ▼
CI: Code Quality / Lint
    │
    ▼
CD: Build Docker Image
    │
    ▼
CD: Push to Registry
    │
    ▼
CD: Deploy to Staging
    │
    ▼
CD: Smoke Tests
    │
    ▼
CD: Deploy to Production
```

---

## 6. Fast Feedback Loop

The whole point of CI/CD:

```text
Without CI/CD:
  Bug introduced Monday
  Found Friday during QA
  4 days of lost context

With CI/CD:
  Bug introduced Monday
  Found Monday morning in CI
  Fixed within hours
```

---

## Key Learning

```text
CI  = Continuous Integration  (auto build + test)
CD  = Continuous Delivery     (auto package, manual deploy)
CD  = Continuous Deployment   (auto package, auto deploy)

The goal: Ship faster. Break less. Catch problems early.
```

---

## Reference

* **CI/CD concepts:** https://docs.github.com/en/actions/about-github-actions/about-continuous-integration
* **Martin Fowler on CI:** https://martinfowler.com/articles/continuousIntegration.html
