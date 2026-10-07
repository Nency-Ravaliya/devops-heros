# 06 — Troubleshooting: the trailing newline Secret bug

**Submitted by:** Piyush Bansal
**Source scenario:** [`../../troubleshooting/secret-base64-gotcha.md`](../../troubleshooting/secret-base64-gotcha.md)

I reproduced the incident from the troubleshooting folder on a live cluster with a real
PostgreSQL 16, then diagnosed and fixed it. All output below is from that run.

## Setup

| File | What it is |
|---|---|
| [postgres.yaml](postgres.yaml) | PostgreSQL. Its admin Secret was made correctly (`echo -n`) |
| [app-secret-broken.yaml](app-secret-broken.yaml) | App credentials made with `echo "mypassword" \| base64` |
| [app.yaml](app.yaml) | "booking-app", logs in to Postgres every 5 s and logs the result |
| [app-secret-fixed.yaml](app-secret-fixed.yaml) | App credentials regenerated with `echo -n` |

```bash
kubectl apply -f postgres.yaml
kubectl apply -f app-secret-broken.yaml -f app.yaml
```

## Before

### 1. Identify the problem

```text
$ kubectl get pods -n s12-hw -l 'app in (postgres,booking-app)'
NAME                          READY   STATUS    RESTARTS   AGE
booking-app-fbbd88d49-c87hx   1/1     Running   0          15m
postgres-f56448f48-4kcth      1/1     Running   0          17m
$ kubectl logs -n s12-hw deploy/booking-app --tail=1
ERROR: psql: error: connection to server at "postgres" (10.96.110.238), port 5432 failed: FATAL:  password authentication failed for user "yatri_admin"
$ kubectl logs -n s12-hw deploy/postgres --tail=2 | cut -c25-
UTC [169] FATAL:  password authentication failed for user "yatri_admin"
UTC [169] DETAIL:  Connection matched file "/var/lib/postgresql/data/pg_hba.conf" line 128: "host all all all scram-sha-256"
```

Both pods are `Running`, so `get pods` alone shows nothing wrong. The logs show the
real problem: the app reaches the database (DNS and Service are fine) but the login is
rejected. So networking is fine and the credentials are the suspect.

### 2. Run troubleshooting commands

Everyone "knows" the password is `mypassword`. Compare what each side actually stores:

```text
$ kubectl get secret postgres-admin -n s12-hw -o jsonpath='{.data.POSTGRES_PASSWORD}'; echo
bXlwYXNzd29yZA==
$ kubectl get secret app-db-creds   -n s12-hw -o jsonpath='{.data.DB_PASSWORD}'; echo
bXlwYXNzd29yZAo=
$ kubectl get secret app-db-creds -n s12-hw -o jsonpath='{.data.DB_PASSWORD}' | base64 -d | xxd
00000000: 6d79 7061 7373 776f 7264 0a              mypassword.
$ kubectl exec -n s12-hw deploy/booking-app -- sh -c 'printf %s "$DB_PASSWORD" | wc -c'
11
```

### 3. Root cause

The two base64 strings differ only in the tail (`...ZA==` vs `...ZAo=`). Decoding with
`xxd` shows the extra byte `0a`, a **newline**. Inside the container the password is
11 characters (`mypassword\n`), not 10.

The app Secret had been generated with `echo "mypassword" | base64`. `echo` appends a
newline, and base64 faithfully encodes it. Postgres compares exact bytes and rejects it.

This is hard to spot because `kubectl describe secret` only shows byte counts, and
printing the decoded value in a terminal looks correct because the newline is invisible.

## Fix

### 4. Fix the issue

```text
$ echo -n 'mypassword' | base64
bXlwYXNzd29yZA==
$ kubectl apply -f app-secret-fixed.yaml
secret/app-db-creds configured
$ kubectl rollout restart deploy/booking-app -n s12-hw
deployment.apps/booking-app restarted
$ kubectl rollout status deploy/booking-app -n s12-hw
Waiting for deployment "booking-app" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "booking-app" rollout to finish: 1 old replicas are pending termination...
deployment "booking-app" successfully rolled out
```

The restart is required. The app reads the Secret through `env` (`secretKeyRef`), and
environment variables are set once when the container starts. Updating the Secret does
not change them in a running pod.

## After

### 5. Verify

```text
$ kubectl exec -n s12-hw deploy/booking-app -- sh -c 'printf %s "$DB_PASSWORD" | wc -c'
10
$ kubectl logs -n s12-hw deploy/booking-app --tail=2
connected as yatri_admin
connected as yatri_admin
```

Password is now 10 bytes and the app logs in.

## Before / after summary

| | Before | After |
|---|---|---|
| base64 in Secret | `bXlwYXNzd29yZAo=` | `bXlwYXNzd29yZA==` |
| Decoded bytes | `mypassword\n` (11) | `mypassword` (10) |
| App log | `password authentication failed` | `connected as yatri_admin` |

## How to prevent it

- Always `echo -n` (or `printf '%s'`) when base64-encoding by hand.
- Better: let kubectl encode it.
  `kubectl create secret generic app-db-creds --from-literal=DB_PASSWORD=mypassword`
  or use `stringData:` in YAML, which takes plain text and has no base64 step.
- Quick check: a base64 value ending in `o=` or `K` often means a trailing newline.
  Pipe it through `base64 -d | xxd` and look for `0a`.

## Troubleshooting commands used

| Command | What it told me |
|---|---|
| `kubectl get pods` | Pods running, so not a crash/scheduling problem |
| `kubectl logs` (app and db) | Auth failure, so network OK and credentials suspect |
| `kubectl get secret -o jsonpath` | The two "same" passwords have different base64 |
| `base64 -d \| xxd` | Extra `0a` byte |
| `kubectl exec ... wc -c` | Confirms what the running container actually has |
| `kubectl rollout restart` / `status` | Roll the fix out to new pods |
