# 🍿 CINERA (Netflix Clone) - Complete DevOps Engineer Roadmap & Architectural Guide

Welcome to the **Complete DevOps Engineer Roadmap & Architecture Guide** modeled after building and deploying a real-world enterprise streaming platform: **CINERA** (a full-stack Netflix clone).

This guide explains the core DevOps philosophy, software development lifecycle (SDLC), tools, and step-by-step career roadmap taught in DevOps Session 1, using **CINERA** as our hands-on architectural example.

---

## 🚀 1. What is DevOps & Why Does CINERA Need It?

### A. The Evolution: Traditional IT vs. DevOps

In traditional IT setups, Development teams (Dev) and Operations teams (Ops) worked in isolated silos:
* **Dev Team**: Built CINERA features (User Authentication, Video Player) and handed code over to Ops.
* **Ops Team**: Responsible for deploying code to servers manually.
* **Problem**: Frequent broken deployments, manual server configuration drift, and the classic excuse: *"Works on my machine, but crashes in production!"*

**DevOps (Development + Operations)** is a cultural mindset, set of practices, and automated tooling that bridges the gap between building software and running it reliably in production.

---

### B. Core Benefits of DevOps for CINERA

| Traditional Deployment | CINERA DevOps Pipeline |
| :--- | :--- |
| Manual deployments once a month | Automated CI/CD deployments multiple times a day |
| Long video buffering & manual server restarts | Auto-scaling servers & self-healing containers |
| Hard-to-find bugs in production | Real-time monitoring & continuous log aggregation |
| Environment mismatch (Local vs Server) | Immutable Docker containers guaranteed to run anywhere |

---

## 🔄 2. The 8 Stages of the DevOps Lifecycle for CINERA

```text
[ 1. PLAN ] ──> [ 2. CODE ] ──> [ 3. BUILD ] ──> [ 4. TEST ]
     ^                                                  │
     │                                                  v
[ 8. MONITOR ] <── [ 7. OPERATE ] <── [ 6. DEPLOY ] <── [ 5. RELEASE ]
```

### 1. **Plan** 📋
* **What happens**: Product features (e.g., CINERA 4K Video Streaming, User Recommendations) are broken into tasks.
* **Tools**: Jira, Trello, GitHub Issues.

### 2. **Code** 💻
* **What happens**: Developers write React frontend and Node.js Express backend code.
* **Tools**: Git, GitHub, VS Code.

### 3. **Build** 🏗️
* **What happens**: Code is compiled and packaged with dependencies into container images.
* **Tools**: npm, Vite, Docker.

### 4. **Test** 🧪
* **What happens**: Automated unit, integration, and security tests verify CINERA API health.
* **Tools**: Jest, Cypress, SonarQube.

### 5. **Release** 🚀
* **What happens**: Tested container images are version-tagged and pushed to a container registry.
* **Tools**: Docker Hub, AWS ECR, GitHub Packages.

### 6. **Deploy** 📦
* **What happens**: Automated pipelines deploy CINERA containers to cloud servers zero-downtime.
* **Tools**: GitHub Actions, Jenkins, Kubernetes, Helm.

### 7. **Operate** ⚡
* **What happens**: Managing active cloud infrastructure, load balancing, and scaling instances during peak streaming hours (e.g. weekend movie releases).
* **Tools**: Nginx, AWS EC2, Kubernetes Auto-scaler.

### 8. **Monitor** 📊
* **What happens**: Tracking API response latency, CPU usage, and log errors in real-time.
* **Tools**: Prometheus, Grafana, ELK Stack (Elasticsearch, Logstash, Kibana).

---

## 🗺️ 3. Complete DevOps Engineer Career Roadmap

To master DevOps and build systems like CINERA, follow this structured 8-step roadmap:

```text
Step 1: Linux & Command Line Basics
  │
  ├──> Step 2: Networking & Security Fundamentals
  │
  ├──> Step 3: Git & Version Control System
  │
  ├──> Step 4: Scripting & Automation (Bash / Python)
  │
  ├──> Step 5: Containerization (Docker & Docker Compose)
  │
  ├──> Step 6: Continuous Integration & Deployment (CI/CD)
  │
  ├──> Step 7: Cloud Providers & Infrastructure as Code (AWS & Terraform)
  │
  └──> Step 8: Observability, Logging & Monitoring (Prometheus & Grafana)
```

---

### Step 1: Linux Administration & Command Line
* **Why**: Over 90% of cloud servers and Docker containers run Linux.
* **Key Skills**: Shell navigation, file permissions (`chmod`), process tracking (`ps`, `top`), service configuration (`etc/`).
* **Reference**: See `session2-linux/CINERA_LINUX_GUIDE.md`.

### Step 2: Computer Networking & Protocols
* **Why**: CINERA services need to securely communicate across public and private networks.
* **Key Skills**: IP addressing, CIDR notation, subnets, HTTP/HTTPS, DNS, SSH, NAT.
* **Reference**: See `session4-networking/CINERA_NETWORKING_GUIDE.md`.

### Step 3: Version Control with Git & GitHub
* **Why**: Collaborating with development teams without overwriting code.
* **Key Skills**: Staging, committing, feature branching, merge conflict resolution, Pull Requests (PRs).
* **Reference**: See `session5-git-github/CINERA_GIT_GUIDE.md`.

### Step 4: Shell Scripting & Automation
* **Why**: Automating repetitive server maintenance, database backups, and health checks.
* **Key Skills**: Bash variables, conditional logic (`if`), loops (`for`/`while`), functions, log redirection.
* **Reference**: See `session3-shell-scripting/CINERA_SHELL_SCRIPTING_GUIDE.md`.

### Step 5: Containerization with Docker
* **Why**: Package CINERA code, Node.js runtime, and dependencies into a lightweight, isolated container.
* **Key Skills**: Dockerfiles, image building, multi-stage builds, Docker Compose, networking, volumes.
* **Reference**: See `session6-docker/CINERA_DOCKER_GUIDE.md`.

### Step 6: CI/CD Pipelines
* **Why**: Automatically build, test, and deploy CINERA on every Git push.
* **Key Skills**: GitHub Actions workflows, Jenkins pipelines, build triggers, automated testing.

### Step 7: Cloud Providers & Infrastructure as Code (IaC)
* **Why**: Provisioning cloud servers (AWS EC2, S3 for videos) automatically using code.
* **Key Skills**: AWS, Terraform, CloudFormation, Ansible.

### Step 8: Observability, Monitoring & Logging
* **Why**: Ensuring 99.99% uptime for CINERA and detecting streaming bottlenecks immediately.
* **Key Skills**: Prometheus metrics, Grafana dashboards, log aggregation with ELK or Loki.

---

## 🏗️ 4. CINERA End-to-End Production Architecture

```text
                                [ CLIENT USER ]
                                       │
                                       v
                             [ Route53 DNS ]
                                       │
                                       v
                       [ Nginx Reverse Proxy / Load Balancer ]
                                       │
                     ┌─────────────────┴─────────────────┐
                     │ (Port 80/443)                     │
                     v                                   v
        [ CINERA React Frontend ]               [ CINERA Express API ]
        (Container Cluster)                     (Container Cluster)
                                                         │
                                       ┌─────────────────┴─────────────────┐
                                       │                                   │
                                       v                                   v
                           [ MongoDB Database ]                    [ Redis Cache ]
                           (User Profiles & Movies)                (Video Session Token Cache)
```

---

## 📋 Summary of All Session Guides Created

You now have a complete, production-ready guide for every single session in your repository using **CINERA** as the unified real-world example:

1. **`session1-devops-engineer-roadmap/CINERA_DEVOPS_ROADMAP_GUIDE.md`** (DevOps Principles & Roadmap)
2. **`session2-linux/CINERA_LINUX_GUIDE.md`** (Linux Administration & Commands)
3. **`session3-shell-scripting/CINERA_SHELL_SCRIPTING_GUIDE.md`** (Bash Automation & Scripting)
4. **`session4-networking/CINERA_NETWORKING_GUIDE.md`** (Networking, IP Addressing & Subnetting)
5. **`session5-git-github/CINERA_GIT_GUIDE.md`** (Git & GitHub Collaboration)
6. **`session6-docker/CINERA_DOCKER_GUIDE.md`** (Docker Containerization & Compose)
