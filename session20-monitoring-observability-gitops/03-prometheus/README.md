# 03 - Prometheus

Prometheus is a monitoring and observability tool focused mainly on metrics.

Think:

> "Prometheus goes around asking applications: 'Give me your metrics.'"

---

# Architecture

```text
Application
    |
    | /metrics
    v
Prometheus
    |
    v
Time-series data
```

Prometheus commonly **pulls/scrapes** metrics.

---

# What Is a Metric?

Example:

```text
http_requests_total 150
```

Prometheus stores values over time.

Imagine:

```text
10:00 -> 100 requests
10:01 -> 120 requests
10:02 -> 150 requests
```

Now we can graph the number.

---

# Start Prometheus

Make sure Docker is running.

```bash
docker compose up -d
```

Check:

```bash
docker compose ps
```

Expected shape:

```text
NAME                    STATUS
session20-prometheus    running
```

Open:

```text
http://localhost:9090
```

---

# Check Prometheus Metrics

Open:

```text
http://localhost:9090/metrics
```

You will see Prometheus's own metrics.

You can also query:

```text
up
```

In the Prometheus UI.

Expected result contains:

```text
up{instance="prometheus:9090",job="prometheus"} 1
```

`1` means the target is up.

---

# Query Examples

Try:

```text
up
```

Then:

```text
prometheus_http_requests_total
```

Then:

```text
process_cpu_seconds_total
```

The exact number of returned series changes as Prometheus runs.

---

# Important Prometheus Words

```text
Target
Scrape
Metric
Label
Query
```

Example:

```text
Prometheus
    |
    +-- Target: application
    |
    +-- Scrape: GET /metrics
    |
    +-- Store: time-series
    |
    +-- Query: PromQL
```

---

# PromQL

PromQL is Prometheus Query Language.

Simple:

```text
up
```

Aggregation example:

```text
sum(up)
```

For a beginner, remember:

> PromQL is the language we use to ask Prometheus questions.

---

# Stop

```bash
docker compose down
```

---

# Practice

Answer:

1. What does Prometheus collect?
2. What is a scrape?
3. What does `up` mean?
4. What is PromQL?
5. Is Prometheus primarily a metrics system or a log storage system?

Expected:

```text
Metrics
Scrape = collecting metrics
up = target health
PromQL = query language
Metrics
```
