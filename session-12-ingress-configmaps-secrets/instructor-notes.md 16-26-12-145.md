# Instructor Guide — Session 12: Ingress, ConfigMaps & Secrets

* Class Pacing: 120 Minutes
* Environment: Minikube / Kind on macOS/Linux + Ingress Addon + VS Code Terminal Split
* Target Audience: 3rd & 4th Year BCA/MCA Students
* Core Narrative: Decoupled Configuration, Secure Credentials & Single-Entry HTTP Routing via Ingress

---

## 1. Class Overview & Pacing (120 Minutes)

| Time | Topic | Core Focus | Code File / Lab |
| :--- | :--- | :--- | :--- |
| **00 – 15 min** | The Cloud Cost Problem | Why creating a cloud LoadBalancer for every microservice is unsustainable. | Cost analysis |
| **15 – 35 min** | Ingress & Routing | Ingress Controller vs Resource; Path & Host routing; Cloud instance testing. | `03-ingress/ingress-routes.yaml`, `03-ingress/ingress-tls.yaml` |
| **35 – 55 min** | Decoupled Config: ConfigMaps | Externalizing environment variables; 12-Factor App rules. | `01-configmap/app-config.yaml` |
| **55 – 75 min** | Sensitive Credentials: Secrets | `data` (Base64) vs `stringData`; Encryption at rest; `echo -n` trap. | `02-secret/db-secret.yaml` |
| **75 – 95 min** | Workload Injection & TLS | `envFrom` injection into deployment; TLS self-signed certificates. | `04-full-demo/backend.yaml`, `LAB-EXERCISES.md` |
| **95 – 110 min** | Cloud Instance Lab Drills | Students execute progressive hands-on tasks on cloud instances. | `LAB-EXERCISES.md` |
| **110 – 120 min** | Rapid-Fire Quiz & Memory Map | Socratic review, live triage, and key architectural takeaways. | Rapid-Fire Q&A |


---

## 2. Step 1: The Cloud Cost Problem & The Need for Ingress (00 – 15 min)

### Concept Explanation:
Start class with an industry cost question:

> "In Session 11, we saw that a `LoadBalancer` service creates an external cloud load balancer. If our company has 20 microservices (auth, payments, cart, search, reviews...), and AWS charges ~$20/month per Network Load Balancer, we are spending $400/month just on load balancers! Can we use ONE single load balancer and route traffic to 20 services based on URL paths?"

Yes! That is what **Ingress** is designed for.

Draw this on the board:

```text
WITHOUT INGRESS (Expensive & Messy):
Client ---> [AWS NLB 1 ($20)] ---> auth-service:80
Client ---> [AWS NLB 2 ($20)] ---> payment-service:80
Client ---> [AWS NLB 3 ($20)] ---> booking-service:80

WITH INGRESS (Clean & Cost-Effective):
                       Client
                          |
             http://yatri.local (Port 80/443)
                          |
                          v
         +---------------------------------+
         |    SINGLE INGRESS CONTROLLER    |
         |         (e.g. NGINX)            |
         +---------------------------------+
           |                             |
     /api (/|$)(.*)                      /
           |                             |
           v                             v
   backend-service:5000          frontend-service:80
```

---

## 3. Step 2: Ingress Controller vs Ingress Resource (15 – 40 min)

### Relatable Student Analogy: The International Airport Terminal
* **The Airport Building (Ingress Controller):** The physical infrastructure with customs booths, runways, and signposts. In Kubernetes, this is usually the NGINX Ingress Controller pod running in `ingress-nginx`.
* **The Flight Board / Ticket (Ingress Resource):** The declarative rulebook stating: *"Passengers holding Flight AI-202 board at Gate 4; passengers for 6E-501 board at Gate 9."*

### Hands-on Demo 1: Enabling Ingress & Writing Routes

Enable the Ingress controller in Minikube:
```bash
minikube addons enable ingress
```

Verify controller pod is running:
```bash
kubectl get pods -n ingress-nginx
```

#### Code File: `03-ingress/ingress-routes.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: yatri-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
    - host: yatri.local
      http:
        paths:
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: yatri-backend-service
                port:
                  number: 80
          - path: /()(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: yatri-frontend-service
                port:
                  number: 80
```

### Line-by-Line YAML Breakdown:
* `spec.ingressClassName: nginx` -> Directs this rule to the NGINX Ingress Controller.
* `rules.host: yatri.local` -> Routes traffic based on the HTTP `Host:` header (name-based virtual hosting).
* `paths.path: /api(/|$)(.*)` -> Directs all API traffic to `yatri-backend-service`.
* `paths.path: /()(.*)` -> Directs all remaining root traffic to `yatri-frontend-service`.

#### Run Command:
```bash
kubectl apply -f 03-ingress/ingress-routes.yaml
```

Output:
```text
ingress.networking.k8s.io/yatri-ingress created
```

Inspect Ingress:
```bash
kubectl get ingress
```

Output:
```text
NAME            CLASS   HOSTS         ADDRESS          PORTS   AGE
yatri-ingress   nginx   yatri.local   192.168.49.2     80      22s
```

---

## 4. Step 3: Decoupling Configuration with ConfigMaps (40 – 60 min)

### Concept Explanation:
Ask students:
> "If you hardcode database hostnames or API timeout values inside your Python code or Dockerfile, what happens when you move the application from Development to Staging to Production? You have to rebuild the Docker image! That violates 12-Factor App methodology."

* **ConfigMap:** A Kubernetes object used to store non-confidential configuration key-value pairs.
* Containers consume ConfigMaps as:
  1. Environment variables (`env:` or `envFrom:`)
  2. Command-line arguments
  3. Configuration files mounted in a volume

### Hands-on Demo 2: Creating a ConfigMap

#### Code File: `01-configmap/app-config.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: yatri-app-config
data:
  APP_ENV: "production"
  PORT: "5000"
  DB_HOST: "yatri-db-service"
  DB_PORT: "5432"
  DB_NAME: "yatri_booking_db"
  LOG_LEVEL: "INFO"
```

#### Run Command:
```bash
kubectl apply -f 01-configmap/app-config.yaml
```

Output:
```text
configmap/yatri-app-config created
```

Inspect ConfigMap data:
```bash
kubectl describe configmap yatri-app-config
```

Output shows all keys cleanly populated!

---

## 5. Step 4: Sensitive Credentials with Secrets (60 – 80 min)

### Concept Explanation:
Ask students:
> "Why can't we put database passwords or API keys inside a ConfigMap? Because ConfigMaps are stored in plain text and visible to everyone who can read the namespace. We use **Secrets**."

Explain the critical interview distinction:
* Kubernetes Secrets are **Base64 encoded**, NOT encrypted by default!
* Base64 is an encoding format, NOT encryption. Anyone can decode it with `echo "..." | base64 -d`.
* For true security at rest, Kubernetes integrates with KMS (AWS KMS, HashiCorp Vault) or Cloud Secrets Manager.

### The Two Syntax Modes:
1. `data:` Requires you to pre-encode values into Base64 strings.
2. `stringData:` Accepts plain text and Kubernetes automatically base64-encodes it when saving!

### Hands-on Demo 3: Creating a Secret with `stringData`

#### Code File: `02-secret/db-secret.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: yatri-db-secret
type: Opaque
stringData:
  DB_USER: "yatri_admin"
  DB_PASSWORD: "SuperSecureProductionPassword2026!"
```

#### Run Command:
```bash
kubectl apply -f 02-secret/db-secret.yaml
```

Output:
```text
secret/yatri-db-secret created
```

Inspect Secret:
```bash
kubectl get secret yatri-db-secret -o yaml
```

Show students:
* In `etcd`, `stringData` was automatically converted into `data:` with Base64 values:
  `DB_PASSWORD: U3VwZXJTZWN1cmVQcm9kdWN0aW9uUGFzc3dvcmQyMDI2IQ==`

Demonstrate how easy it is to decode:
```bash
echo "U3VwZXJTZWN1cmVQcm9kdWN0aW9uUGFzc3dvcmQyMDI2IQ==" | base64 -d
```
Output:
```text
SuperSecureProductionPassword2026!
```

---

## 6. Step 5: Injecting ConfigMaps & Secrets into Workloads (80 – 100 min)

### Concept Explanation:
Now demonstrate how a single Deployment consumes both:
* Non-sensitive configs from `yatri-app-config`
* Sensitive credentials from `yatri-db-secret`

#### Code File: `04-full-demo/backend.yaml` (or `LAB-EXERCISES.md`)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: yatri-backend-configured
spec:
  replicas: 2
  selector:
    matchLabels:
      app: yatri-backend-configured
  template:
    metadata:
      labels:
        app: yatri-backend-configured
    spec:
      containers:
        - name: backend
          image: python:3.11-alpine
          command: ["sh", "-c", "echo \"[Config Loaded] Running on DB: $DB_HOST as User: $DB_USER\"; python3 -c 'import http.server; http.server.test(port=5000)'"]
          ports:
            - containerPort: 5000
          envFrom:
            - configMapRef:
                name: yatri-app-config
          env:
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: yatri-db-secret
                  key: DB_USER
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: yatri-db-secret
                  key: DB_PASSWORD
```

#### Apply Command:
```bash
kubectl apply -f 04-full-demo/backend.yaml
```

Output:
```text
deployment.apps/yatri-backend-configured created
```

Check the container logs to verify both ConfigMap and Secret were injected:
```bash
kubectl logs -l app=yatri-backend-configured
```

Output:
```text
[Config Loaded] Running on DB: yatri-db-service as User: yatri_admin
Serving HTTP on 0.0.0.0 port 5000 ...
```

---

## 7. Step 6: Intentional Failure: The Base64 Newline Trap (100 – 110 min)

### Concept Explanation:
Walk students through the classic gotcha documented in `troubleshooting/secret-base64-gotcha.md`:

> "When developers create secrets on the terminal, they often run:  
> `echo "my-password" | base64`  
> What is wrong with that? `echo` automatically appends an invisible newline character (`\n`) at the end of the string!"

Demonstrate the difference live:
```bash
# BAD (Has invisible newline):
echo "mypassword" | base64
# Output: bXlwYXNzd29yZAo=

# GOOD (No newline using -n flag):
echo -n "mypassword" | base64
# Output: bXlwYXNzd29yZA==
```

Trainer Script:
> *"Notice the difference between `bXlwYXNzd29yZAo=` and `bXlwYXNzd29yZA==`!  
> That one tiny `\n` character means your application sends `mypassword\n` to PostgreSQL, and the database rejects the login with 'FATAL: password authentication failed for user'!  
> Always use `echo -n` or use `stringData:` in your YAML to let Kubernetes handle encoding safely!"*

---

## 8. Step 7: Classroom Quiz & Socratic Review (110 – 120 min)

Ask students these 10 questions:

### Q1. What is the fundamental difference between an Ingress Controller and an Ingress Resource?
> The Ingress Controller is the running reverse-proxy application (e.g. NGINX pod). The Ingress Resource is the declarative YAML configuration containing routing rules.

### Q2. Why is Ingress preferred over creating multiple `LoadBalancer` services?
> Ingress consolidates routing under a single cloud load balancer and IP address, saving substantial cloud costs and simplifying SSL/TLS termination.

### Q3. What is the difference between a ConfigMap and a Secret?
> ConfigMaps are designed for non-confidential configuration (hostnames, ports). Secrets are designed for sensitive data (passwords, tokens, private keys).

### Q4. Are Kubernetes Secrets encrypted by default?
> No. By default, they are only Base64-encoded plain text.

### Q5. What is the difference between `data:` and `stringData:` in a Secret manifest?
> `data:` requires pre-encoded Base64 strings. `stringData:` accepts plain human-readable text and Kubernetes automatically base64-encodes it.

### Q6. How can an application consume a ConfigMap as files instead of environment variables?
> By mounting the ConfigMap as a volume (`spec.volumes[].configMap`) into a container filesystem path.

### Q7. What happens if you update a ConfigMap that is injected as environment variables?
> The running containers do NOT automatically update. The pods must be restarted (e.g. `kubectl rollout restart deployment/<name>`) to pick up new environment variables.

### Q8. What happens if you update a ConfigMap that is mounted as a volume?
> Kubernetes automatically updates the mounted files inside the container after a short delay (typically 10–60 seconds).

### Q9. What does the `echo -n` flag do when generating Base64 secrets?
> It suppresses the trailing newline character, preventing corrupt passwords.

### Q10. What annotation in an Ingress manifest enables URL rewriting?
> `nginx.ingress.kubernetes.io/rewrite-target`.

---

## 9. Final One-Minute Memory Map

```text
                  INGRESS, CONFIGMAPS & SECRETS
                                |
        -------------------------------------------------
        |                       |                       |
     INGRESS                CONFIGMAP                 SECRET
        |                       |                       |
 Single HTTP Entry       Non-Sensitive Config    Sensitive Credentials
 (Path / Host Routing)   (Ports, DB Names)       (Passwords, API Keys)
        |                       |                       |
 Consolidates LBs        env / envFrom           stringData (No newline)
```

Golden rules:
* **Ingress**: One load balancer to route all microservices.
* **ConfigMap**: Environment settings outside the image.
* **Secret**: Passwords encoded and injected securely.
