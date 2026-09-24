# 05 - Jobs and Steps

## 1. Jobs

A workflow can contain multiple jobs.

**Example:**
```yaml
jobs:
  build:
    ...
  test:
    ...
```

Our workflow has:

```mermaid
flowchart TD
    A[Workflow] --> B[Build Job]
    A --> C[Test Job]
```

---

## 2. Steps

Each job contains multiple steps.

**Example:**
```yaml
steps:
  - name: Build
    run: echo "Building..."
  - name: Test
    run: echo "Testing..."
```

---

## 3. Job vs Step

| **Job** | **Step** |
|:---|:---|
| Larger unit | Smaller unit |
| Contains steps | Executes one task |
| Has its own runner | Runs inside job |
| Can depend on another job | Executes in order |

---

## 4. Our Pipeline

```mermaid
flowchart TD
    A[Workflow] --> B[Build Job]
    B --> B1[Checkout]
    B --> B2[Build]
    B --> B3[Finish]

    A --> C[Test Job]
    C --> C1[Test 1]
    C --> C2[Test 2]
    C --> C3[Finish]
```

---

## 5. Expected Output

**Build:**
```text
Building application...
Build successful!
```

**Test:**
```text
Running test 1
Running test 2
All tests passed!
```

---

## 6. Important Point

Steps inside one job execute **sequentially**.

Jobs can run independently unless dependencies are defined.

To make one job wait for another:
```yaml
needs: build
```

**Example:**
```yaml
test:
  needs: build
```

**Then:**
```mermaid
flowchart TD
    A[Build] --> B[Test]
```

---

### 💡 Key Takeaway

> **Workflow** → **Jobs** → **Steps**
