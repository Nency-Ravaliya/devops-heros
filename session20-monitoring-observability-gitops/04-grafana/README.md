# 04 - Grafana

Prometheus stores and queries metrics.

Grafana helps us **see** them.

Think:

```text
Prometheus = Data
Grafana    = Beautiful dashboard
```

---

# Architecture

```text
Application
     |
     v
 Prometheus
     |
     v
  Metrics
     |
     v
  Grafana
     |
     v
 Dashboard
```

---

# Start

```bash
docker compose up -d
```

Check:

```bash
docker compose ps
```

Expected shape:

```text
session20-prometheus    running
session20-grafana       running
```

Open:

```text
Prometheus:
http://localhost:9090

Grafana:
http://localhost:3000
```

---

# Grafana Login

For this classroom demo:

```text
Username: admin
Password: admin
```

Grafana may ask you to change the password after login.

Do not use these default credentials in production.

---

# Add Prometheus Data Source

Inside Grafana:

```text
Connections
   |
Data sources
   |
Add data source
   |
Prometheus
```

Use this URL:

```text
http://prometheus:9090
```

Important:

The Grafana container talks to the Prometheus container using the Docker Compose service name.

Then click:

```text
Save & test
```

Expected:

```text
Successfully queried the Prometheus API.
```

The exact UI wording can vary by Grafana version.

---

# Create a Simple Dashboard

Create:

```text
Dashboard
   |
Add visualization
```

Select the Prometheus data source.

Query:

```text
up
```

Choose a visualization such as:

```text
Stat
```

You should see:

```text
1
```

Meaning the Prometheus target is up.

---

# Why Grafana?

Imagine having:

```text
CPU
Memory
Requests
Errors
Latency
```

A dashboard can put everything together:

```text
+----------------+----------------+
| CPU            | Memory         |
| 72%            | 61%            |
+----------------+----------------+
| Requests/sec   | Error Rate     |
| 150            | 1.2%           |
+----------------+----------------+
| Latency                         |
| 230 ms                          |
+---------------------------------+
```

Humans understand pictures faster than raw numbers.

---

# Stop

```bash
docker compose down
```

---

# Key Point

Remember:

```text
Prometheus -> collects/stores metrics
Grafana    -> visualizes metrics
```
