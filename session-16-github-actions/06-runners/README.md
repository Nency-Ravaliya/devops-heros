# Runners

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
```

`runs-on:` tells GitHub Actions which machine to use.

---

## 1. What is a Runner?

A runner is a machine that executes your workflow jobs.

```text
Workflow starts
      │
      ▼
GitHub finds a runner
      │
      ▼
Runner clones the repository
      │
      ▼
Runner executes each step
      │
      ▼
Runner reports success or failure to GitHub
```

---

## 2. GitHub-Hosted Runners

GitHub provides free virtual machines you can use immediately.

```text
ubuntu-latest      = Ubuntu Linux (most common)
ubuntu-22.04       = Ubuntu 22.04 specifically
ubuntu-20.04       = Ubuntu 20.04 specifically
windows-latest     = Windows Server
macos-latest       = macOS
macos-14           = macOS Sonoma
```

Usage:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
```

GitHub manages the machine. You pay nothing for public repositories.

---

## 3. What is Pre-installed on ubuntu-latest?

```text
Git
Docker
Python 3.x
Node.js
Java (JDK)
Go
Ruby
AWS CLI
kubectl
Helm
```

You do not need to install most standard tools.

---

## 4. Self-Hosted Runners

You can register your own machine as a runner.

Use cases:

```text
Need specific hardware (GPU, high memory)
Private network access (internal database, VPN)
Custom software not available on GitHub runners
Cost (large workloads, GitHub-hosted becomes expensive)
```

Register a self-hosted runner:

```text
1. Go to GitHub repository > Settings > Actions > Runners
2. Click "New self-hosted runner"
3. Follow the download and configure steps
4. Start the runner agent on your machine
```

Use it in a workflow:

```yaml
jobs:
  build:
    runs-on: self-hosted
```

---

## 5. Runner Labels

Self-hosted runners can have labels to target specific machines:

```yaml
jobs:
  deploy:
    runs-on: [self-hosted, linux, gpu]
```

This runs on a self-hosted runner that has all three labels.

---

## 6. Runner Environments

GitHub-hosted runners are fresh every time:

```text
Each job gets a brand new virtual machine
Nothing persists between jobs
This is good: clean, reproducible, no state leakage
```

Self-hosted runners are persistent:

```text
The same machine runs multiple jobs
State can persist (cache, files)
This requires cleanup discipline
```

---

## 7. Matrix Builds

Test across multiple environments at once:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11']
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: pytest
```

This creates three parallel jobs, one for each Python version.

---

## Key Learning

```text
GitHub-hosted runner = fresh VM, managed by GitHub, free for public repos
Self-hosted runner   = your machine, persistent, full control
runs-on: ubuntu-latest = most common choice
matrix:              = run the same job across multiple configurations
```

---

## Reference

* **GitHub-hosted runners:** https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
* **Self-hosted runners:** https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners
