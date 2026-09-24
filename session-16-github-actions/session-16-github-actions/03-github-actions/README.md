# 03 - GitHub Actions

## 1. What is GitHub Actions?

GitHub Actions is an automation platform built into GitHub.

It can automatically:
* Build code
* Test code
* Run scripts
* Create packages
* Upload artifacts
* Deploy applications

---

## 2. Workflow File

Our workflow is located at:

```text
.github/workflows/hello-actions.yml
```

---

## 3. Workflow Code

```yaml
name: Hello GitHub Actions
on:
  workflow_dispatch:
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: Print message
        run: echo "Hello from GitHub Actions!"
      - name: Show date
        run: date
      - name: Show operating system
        run: uname -a
```

---

## 4. Run the Workflow

Push the repository to GitHub.

1. Open **GitHub Repository**
2. Go to **Actions**
3. Select **Hello GitHub Actions**
4. Click **Run workflow**

---

## 5. Expected Output

* **The Print message step:**
  ```text
  Hello from GitHub Actions!
  ```

* **The date step:**
  ```text
  Wed Sep 23 ...
  ```
  *(The exact date and time will be different.)*

* **The OS step:** Displays Linux runner information.

---

## 6. Important Concepts

```mermaid
flowchart TD
    A[GitHub Repository] --> B[GitHub Actions]
    B --> C[Workflow]
    C --> D[Job]
    D --> E[Steps]
```

---

### 💡 Key Takeaway
> GitHub Actions allows us to automate tasks directly from GitHub.
