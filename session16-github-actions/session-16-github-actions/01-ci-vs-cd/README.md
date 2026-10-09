# 01 - CI vs CD

### Objective
Understand the difference between:
* **Continuous Integration (CI)**
* **Continuous Delivery (CD)**
* **Continuous Deployment (CD)**

---

## 1. What is CI?
**CI means Continuous Integration.**

Developers frequently push their code to a shared repository.
Every change can automatically trigger a pipeline:

```mermaid
flowchart LR
    A[Code Push] --> B[Build]
    B --> C[Test]
    C --> D{PASS / FAIL}
```

### Example

```mermaid
flowchart TD
    A[Developer] -->|git push| B[GitHub]
    B --> C[GitHub Actions]
    C --> D[Build]
    D --> E[Tests]
    E --> F[PASS]
```

---

## 2. What is CD?
**CD means Continuous Delivery or Continuous Deployment.**

After the code passes CI, the application can move toward release or deployment.

```mermaid
flowchart LR
    A[Code] --> B[Build]
    B --> C[Test]
    C --> D[Package]
    D --> E[Deploy]
```

---

## 3. CI vs CD

| **CI** | **CD** |
|:---|:---|
| Integrates code | Delivers/deploys code |
| Builds application | Releases application |
| Runs tests | Runs deployment process |
| Finds problems early | Automates release |
| Developer-focused validation | Release/deployment-focused |

---

## 4. CI Example

```mermaid
flowchart LR
    A[Developer] -->|git push| B[Build]
    B --> C[Unit Tests]
    C --> D[PASS]
```

---

## 5. CD Example

```mermaid
flowchart LR
    A[CI] --> B[Build]
    B --> C[Test]
    C --> D[Package]
    D --> E[Deploy to Server]
```

---

## 6. Real-World Example

A developer changes an application.

```bash
git add .
git commit -m "Update application"
git push
```

The CI system automatically:
**Checkout** → **Build** → **Test**

If everything passes:
**Build** → **Test** → **Deploy**

---

### 💡 Key Takeaway

> **CI** = Build + Test + Validate
> **CD** = Deliver / Deploy

* CI makes sure the code is healthy.
* CD automates getting that healthy code toward users.