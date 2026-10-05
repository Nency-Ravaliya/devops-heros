# 01 - Monitoring vs Observability

```text
Monitoring
Observability
```

They are related, but not exactly the same.

---

# Monitoring

Monitoring asks:

> "Is the system healthy?"

Example dashboard:

```text
CPU:        82%
Memory:     70%
Requests:   500/sec
Errors:     20/sec
Latency:    900ms
```

We can create an alert:

```text
IF error_rate > 5%
THEN alert
```

Monitoring is excellent for known problems.

---

# Observability

Observability asks:

> "Why is the system behaving this way?"

Imagine:

```text
Users say:
"The website is slow."
```

Monitoring tells us:

```text
Latency = 2 seconds
```

Observability helps us investigate:

```text
Request
   |
   +-- API = 500ms
   |
   +-- User Service = 200ms
   |
   +-- Payment Service = 100ms
   |
   +-- Database = 1.2s
```

Now we have a clue:

```text
Database = slow
```

---

# Analogy

Imagine a car.

## Monitoring

Dashboard says:

```text
Engine temperature = HIGH
```

We know something is wrong.

## Observability

We inspect:

```text
Coolant level
Engine logs
Temperature history
Sensor readings
```

Now we can investigate why.

---

# Three Main Signals

Observability commonly uses:

```text
Metrics
Logs
Traces
```

Think:

```text
Metrics = Numbers
Logs    = Events
Traces  = Journey
```

---

# Monitoring vs Observability

| Monitoring | Observability |
|---|---|
| Is something wrong? | Why is it wrong? |
| Known failure signals | Explore unknown problems |
| Dashboards/alerts | Metrics + logs + traces |
| Health view | Deep investigation |

They are not competitors btw.

A production system normally uses both.

---

# Example

Suppose:

```text
Website feels slow
```

Monitoring:

```text
Latency > 1 second
```

Observability:

```text
Trace shows:
API -> Order Service -> Database

Database query = 850ms
```

Now the team has a much better starting point.

---

# Key Point

```text
Monitoring:
"Tell me when something is wrong."

Observability:
"Give me enough information to understand what happened."
```
