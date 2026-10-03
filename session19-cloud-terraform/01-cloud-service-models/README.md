# 01 - Cloud Service Models

Cloud computing means:

> Instead of buying and maintaining all the computers yourself, you rent computing resources from a cloud provider.

Examples of cloud providers:

- AWS
- Microsoft Azure
- Google Cloud

---

## The Three Big Service Models

There are three words students should remember:

```text
IaaS
PaaS
SaaS
```

### IaaS - Infrastructure as a Service

Cloud gives you the basic building blocks.

You manage more things yourself.

```text
You
 |
 +-- Application
 +-- Runtime
 +-- OS
 +-- Configuration
 |
Cloud
 |
 +-- Virtual Machine
 +-- Storage
 +-- Network
```

AWS examples:

```text
EC2
EBS
VPC
```

Example:

> "Give me a virtual server. I will install Java, configure Nginx and deploy my application."

---

## PaaS - Platform as a Service

The cloud manages more of the platform for you.

```text
You
 |
 +-- Application
 |
Cloud
 |
 +-- Runtime
 +-- OS
 +-- Servers
 +-- Infrastructure
```

Examples:

```text
AWS Elastic Beanstalk
Azure App Service
Google App Engine
```

Example:

> "I have a Java application. AWS handle the server setup and I will focus on my application."

---

## SaaS - Software as a Service

You simply use the software.

```text
You
 |
 v
Application
 |
Cloud manages almost everything
```

Examples:

```text
Gmail
Google Docs
Microsoft 365
Slack
```

Example:

> "I want to use email. AWS handle the server setup and I will focus on my work."

---

## Easy Comparison

| Model | You mainly manage | Example |
|---|---|---|
| IaaS | VM, OS, application | EC2 |
| PaaS | Application/code | Elastic Beanstalk |
| SaaS | Mostly just usage/data | Gmail |

Remember:

```text
IaaS -> More control, more responsibility
PaaS -> Less infrastructure work
SaaS -> Just use the software
```

---

## Analogy

Imagine renting a house.

### IaaS

You rent an empty house.

You arrange many things yourself.

### PaaS

You rent a furnished apartment.

More things are already prepared.

### SaaS

You stay in a hotel.

You mostly just use the service.

---

## Practice

Classify these:

```text
1. EC2
2. Gmail
3. Elastic Beanstalk
4. Google Docs
5. Virtual Machine
```

Expected discussion:

```text
EC2              -> IaaS
Gmail            -> SaaS
Elastic Beanstalk -> PaaS
Google Docs      -> SaaS
Virtual Machine  -> IaaS
```